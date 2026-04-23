source(file.path("R", "utils.R"))
ensure_dir(MODELS_DIR)
ensure_dir(FIGURES_DIR)

if (!file.exists(file.path(PROCESSED_DATA_DIR, "SUBTE_visual_parity_clean.csv"))) {
  source(file.path("R", "02_visual_parity_plots.R"))
}

SUBTE <- readr::read_csv(file.path(PROCESSED_DATA_DIR, "SUBTE_visual_parity_clean.csv"), show_col_types = FALSE) %>%
  mutate(
    LINEA = factor(LINEA, levels = SUBTE_LEVELS_CORE),
    periodo_date = as.Date(periodo_date)
  )

# Mismo corte temporal del script original para modelado
SUBTE_D <- SUBTE %>%
  filter(periodomes <= "2025/07") %>%
  mutate(AÑO = year(periodo_date))

SUBTE_M <- SUBTE %>%
  filter(periodomes <= "2025/07") %>%
  group_by(periodomes, LINEA) %>%
  summarise(
    sueldo_tarifa_subte_priv = first(sueldo_tarifa_subte_priv),
    cantidad = sum(cantidad),
    .groups = "drop"
  ) %>%
  distinct() %>%
  separate(periodomes, c("AÑO", "MES"), "/") %>%
  mutate(
    periodo = str_c(AÑO, "/", MES),
    periodo = as.yearmon(periodo, "%Y/%m"),
    periodo_date = as.Date(periodo),
    AÑO_NUM = as.numeric(AÑO)
  )

readr::write_csv(SUBTE_D, file.path(PROCESSED_DATA_DIR, "SUBTE_D_modelado.csv"))
readr::write_csv(SUBTE_M, file.path(PROCESSED_DATA_DIR, "SUBTE_M_modelado.csv"))

modclaro <- lm(cantidad ~ sueldo_tarifa_subte_priv + LINEA, data = SUBTE_M)
modpred <- lm(cantidad ~ poly(sueldo_tarifa_subte_priv, 3) * LINEA, data = SUBTE_M)

mod1 <- lm(cantidad ~ AÑO_NUM, data = SUBTE_M)
mod2 <- lm(cantidad ~ AÑO_NUM + sueldo_tarifa_subte_priv, data = SUBTE_M)
mod3 <- lm(cantidad ~ AÑO_NUM + sueldo_tarifa_subte_priv + LINEA, data = SUBTE_M)
mod4 <- lm(cantidad ~ AÑO_NUM + sueldo_tarifa_subte_priv * LINEA, data = SUBTE_M)
mod5 <- lm(cantidad ~ (AÑO_NUM + sueldo_tarifa_subte_priv) * LINEA, data = SUBTE_M)
mod5_poly <- lm(cantidad ~ (poly(AÑO_NUM, 2) + poly(sueldo_tarifa_subte_priv, 2)) * LINEA, data = SUBTE_M)

comparison <- tibble(
  model = c("modclaro", "modpred", "mod1", "mod2", "mod3", "mod4", "mod5", "mod5_poly"),
  r_squared = c(summary(modclaro)$r.squared, summary(modpred)$r.squared, summary(mod1)$r.squared,
                summary(mod2)$r.squared, summary(mod3)$r.squared, summary(mod4)$r.squared,
                summary(mod5)$r.squared, summary(mod5_poly)$r.squared),
  adj_r_squared = c(summary(modclaro)$adj.r.squared, summary(modpred)$adj.r.squared, summary(mod1)$adj.r.squared,
                    summary(mod2)$adj.r.squared, summary(mod3)$adj.r.squared, summary(mod4)$adj.r.squared,
                    summary(mod5)$adj.r.squared, summary(mod5_poly)$adj.r.squared)
)

anova_main <- anova(mod1, mod2, mod3, mod4, mod5)
anova_poly <- anova(mod5, mod5_poly)

readr::write_csv(comparison, file.path(MODELS_DIR, "model_comparison.csv"))
readr::write_csv(broom::tidy(mod5), file.path(MODELS_DIR, "mod5_coefficients.csv"))
readr::write_csv(broom::tidy(mod5_poly), file.path(MODELS_DIR, "mod5_poly_coefficients.csv"))
readr::write_csv(as.data.frame(anova_main) %>% tibble::rownames_to_column("step"), file.path(MODELS_DIR, "anova_main.csv"))
readr::write_csv(as.data.frame(anova_poly) %>% tibble::rownames_to_column("step"), file.path(MODELS_DIR, "anova_poly.csv"))

SUBTE_MPREDCLARO <- SUBTE_M %>%
  add_predictions(modclaro, var = "predclaro") %>%
  add_residuals(modclaro, var = "residclaro")

SUBTE_MPRED1 <- SUBTE_M %>%
  add_predictions(modpred, var = "pred") %>%
  add_residuals(modpred, var = "resid")

SUBTE_MPRED <- SUBTE_M %>%
  add_predictions(mod5, var = "pred5") %>%
  add_residuals(mod5, var = "resid5")

readr::write_csv(SUBTE_MPREDCLARO, file.path(MODELS_DIR, "SUBTE_MPREDCLARO.csv"))
readr::write_csv(SUBTE_MPRED1, file.path(MODELS_DIR, "SUBTE_MPRED1.csv"))
readr::write_csv(SUBTE_MPRED, file.path(MODELS_DIR, "SUBTE_MPRED.csv"))

# Gráficos muy parecidos a los del TP
plot_modclaro_fit <- SUBTE_MPREDCLARO %>%
  ggplot() +
  geom_point(aes(y = cantidad, x = sueldo_tarifa_subte_priv, color = LINEA), alpha = 0.5) +
  geom_line(aes(y = predclaro, x = sueldo_tarifa_subte_priv, color = LINEA)) +
  scale_color_manual(values = COLORES_SUBTE_CORE) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 1),
    panel.grid.major = element_line(colour = "gray"),
    panel.background = element_rect(fill = "white", colour = "grey50")
  ) +
  labs(x = "Sueldo/tarifa", y = "Cantidad de Viajes [en millones]") +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = ""), expand = c(0, 0)) +
  scale_color_discrete(labels = c("A", "B", "C", "D", "E", "H"))

ggsave(file.path(FIGURES_DIR, "07_modclaro_ajuste.png"), plot_modclaro_fit, width = 10, height = 6, dpi = 300)

plot_modclaro_resid <- SUBTE_MPREDCLARO %>%
  ggplot() +
  geom_point(aes(x = predclaro, y = residclaro, color = LINEA)) +
  geom_hline(aes(yintercept = 0)) +
  geom_smooth(aes(x = predclaro, y = residclaro), se = FALSE) +
  labs(x = "Predicción", y = "Residuos") +
  scale_color_discrete(labels = c("A", "B", "C", "D", "E", "H")) +
  scale_y_continuous(labels = label_number(scale = 1e-3, suffix = ""), expand = c(0, 0)) +
  scale_x_continuous(labels = label_number(scale = 1e-6, suffix = ""), expand = c(0, 0)) +
  ylim(-500000, 500000) +
  xlim(1000000, 4000000)

ggsave(file.path(FIGURES_DIR, "08_modclaro_residuos.png"), plot_modclaro_resid, width = 10, height = 6, dpi = 300)

plot_modpred_fit <- SUBTE_MPRED1 %>%
  ggplot() +
  geom_point(aes(y = cantidad, x = sueldo_tarifa_subte_priv, color = LINEA), alpha = 0.5) +
  geom_line(aes(y = pred, x = sueldo_tarifa_subte_priv, color = LINEA)) +
  scale_x_log10() +
  scale_color_manual(values = COLORES_SUBTE_CORE) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 1),
    panel.grid.major = element_line(colour = "gray"),
    panel.background = element_rect(fill = "white", colour = "grey50")
  ) +
  labs(x = "Sueldo/tarifa", y = "Cantidad de Viajes [en millones]") +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = ""), expand = c(0, 0)) +
  scale_color_discrete(labels = c("A", "B", "C", "D", "E", "H"))

ggsave(file.path(FIGURES_DIR, "09_modpred_ajuste.png"), plot_modpred_fit, width = 10, height = 6, dpi = 300)

plot_modpred_resid <- SUBTE_MPRED1 %>%
  ggplot() +
  geom_point(aes(x = pred, y = resid, color = LINEA)) +
  geom_hline(aes(yintercept = 0)) +
  geom_smooth(aes(x = pred, y = resid), se = FALSE) +
  labs(x = "Predicción", y = "Residuos") +
  scale_color_discrete(labels = c("A", "B", "C", "D", "E", "H")) +
  scale_y_continuous(labels = label_number(scale = 1e-3, suffix = ""), expand = c(0, 0)) +
  scale_x_continuous(labels = label_number(scale = 1e-6, suffix = ""), expand = c(0, 0)) +
  ylim(-500000, 500000) +
  xlim(1000000, 4000000)

ggsave(file.path(FIGURES_DIR, "10_modpred_residuos.png"), plot_modpred_resid, width = 10, height = 6, dpi = 300)

plot_mod5_fit <- SUBTE_MPRED %>%
  ggplot() +
  geom_point(aes(y = cantidad, x = sueldo_tarifa_subte_priv, color = LINEA), alpha = 0.5) +
  geom_line(aes(y = pred5, x = sueldo_tarifa_subte_priv, color = LINEA)) +
  scale_x_log10() +
  scale_color_manual(values = COLORES_SUBTE) 

ggsave(file.path(FIGURES_DIR, "11_mod5_ajuste.png"), plot_mod5_fit, width = 10, height = 6, dpi = 300)

plot_mod5_resid <- SUBTE_MPRED %>%
  ggplot() +
  geom_point(aes(x = pred5, y = resid5, color = LINEA)) +
  geom_hline(aes(yintercept = 0)) +
  geom_smooth(aes(x = pred5, y = resid5, color = LINEA), se = FALSE)

ggsave(file.path(FIGURES_DIR, "12_mod5_residuos.png"), plot_mod5_resid, width = 10, height = 6, dpi = 300)

saveRDS(
  list(
    modclaro = modclaro,
    modpred = modpred,
    mod1 = mod1,
    mod2 = mod2,
    mod3 = mod3,
    mod4 = mod4,
    mod5 = mod5,
    mod5_poly = mod5_poly
  ),
  file.path(MODELS_DIR, "models_visual_parity.rds")
)

message("Modelado visual-parity listo en outputs/models/ y outputs/figures/")
