source(file.path("R", "utils.R"))
ensure_dir(FIGURES_DIR)

if (!file.exists(file.path(PROCESSED_DATA_DIR, "SUBTE_enriched.csv"))) {
  prepare_base_data()
}

SUBTE <- readr::read_csv(file.path(PROCESSED_DATA_DIR, "SUBTE_enriched.csv"), show_col_types = FALSE) %>%
  mutate(
    LINEA = factor(LINEA, levels = SUBTE_LEVELS_ALL),
    dia = factor(dia, levels = DAY_LEVELS),
    periodo_date = as.Date(periodo_date)
  )

# 1) Boxplot por línea - igual al espíritu del original
plot_lineas <- SUBTE %>%
  ggplot() +
  geom_boxplot(aes(x = cantidad, y = LINEA, fill = LINEA)) +
  labs(
    y = "LINEA",
    x = "Cantidad de viajes por día [en miles]",
    title = "Distribución de viajes diarios por línea de Subte"
  ) +
  scale_x_continuous(labels = label_number(scale = 1e-3), expand = c(0, 0)) +
  original_boxplot_theme() +
  scale_fill_discrete(labels = c("A", "B", "C", "D", "E", "H", "Premetro", "Lin_amarilla_C", "Lin_verde_D")) +
  scale_y_discrete(labels = c("A", "B", "C", "D", "E", "H", "Premetro", "Lin_amarilla_C", "Lin_verde_D")) +
  scale_fill_manual(values = COLORES_SUBTE) +
  guides(fill = "none")

ggsave(file.path(FIGURES_DIR, "01_boxplot_lineas_subte.png"), plot_lineas, width = 11, height = 6, dpi = 300)

# Replico las mismas limpiezas que hacía tu script antes de los siguientes gráficos
SUBTE <- SUBTE %>%
  filter(LINEA != "LIN_AMARILLA_C" & LINEA != "LIN_PREMETRO" & LINEA != "LIN_VERDE_D")

# 2) Boxplot por día de la semana
plot_dias <- SUBTE %>%
  ggplot() +
  geom_boxplot(aes(x = cantidad, y = dia, fill = dia)) +
  scale_x_continuous(labels = label_number(scale = 1e-3), expand = c(0, 0)) +
  original_boxplot_theme() +
  scale_y_discrete(labels = c("Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sábado", "Domingo")) +
  guides(fill = "none") +
  labs(
    x = "Cantidad de viajes por día [en miles]",
    y = "DIA",
    title = "Distribución de la cantidad de viajes en Subte por día de la semana"
  )

ggsave(file.path(FIGURES_DIR, "02_boxplot_dias_semana.png"), plot_dias, width = 11, height = 6, dpi = 300)

# Misma limpieza posterior del original
SUBTE <- SUBTE %>%
  filter(dia != "Saturday" & dia != "Sunday") %>%
  filter(month(periodo_date) != 1 & month(periodo_date) != 2 & month(periodo_date) != 12)

periodo_og <- unique(SUBTE$periodomes)
periodos_reducidos <- breaks_every(periodo_og, by = 3)
periodos_reducidos1 <- breaks_every(periodo_og, by = 6)

# 3) Barras/histograma identidad por mes coloreado por tarifa
plot_barras_tiempo <- SUBTE %>%
  ggplot(aes(x = periodomes, y = cantidad, fill = tarifa_subte_registrada)) +
  geom_col() +
  original_time_theme() +
  scale_x_discrete(breaks = periodos_reducidos) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"), expand = c(0, 0)) +
  labs(
    title = "Cantidad de viajes en Subte a lo largo del tiempo.",
    subtitle = "Desde 2020 hasta actualidad. Coloreado por el precio del pasaje.",
    y = "Viajes [millones]",
    x = "Mes",
    fill = "Precio pasaje\n[ARS]"
  ) +
  scale_fill_gradient(low = "lightblue") +
  coord_cartesian(ylim = c(0, 30000000))

ggsave(file.path(FIGURES_DIR, "03_barras_subte_tiempo.png"), plot_barras_tiempo, width = 12, height = 6, dpi = 300)

# 4) Scatter chequeo abril
plot_scatter_abril <- SUBTE %>%
  group_by(periodomes) %>%
  summarise(cantidad = sum(cantidad), tarifa_subte_registrada = first(tarifa_subte_registrada), .groups = "drop") %>%
  ggplot(aes(x = periodomes, y = cantidad)) +
  geom_point(size = 3) +
  scale_x_discrete(breaks = periodos_reducidos) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"), expand = c(0, 0)) +
  labs(
    title = "Cantidad de viajes en Subte a lo largo del tiempo.",
    subtitle = "Desde Abril de 2022 hasta la actualidad.",
    y = "Viajes",
    x = "Mes",
    color = "Precio pasaje\n[ARS]"
  ) +
  coord_cartesian(ylim = c(0, 30000000)) +
  original_time_theme()

ggsave(file.path(FIGURES_DIR, "04_scatter_revision_abril.png"), plot_scatter_abril, width = 12, height = 6, dpi = 300)

# Replico el corte visual original
SUBTE <- SUBTE %>% filter(periodomes >= "2022/04")

# 5) Scatter desde enero 2022 (aunque el corte ya se decidió en abril, lo dejo porque estaba en tu script)
plot_scatter_enero <- SUBTE %>%
  group_by(periodomes) %>%
  summarise(cantidad = sum(cantidad), tarifa_subte_registrada = first(tarifa_subte_registrada), .groups = "drop") %>%
  ggplot(aes(x = periodomes, y = cantidad)) +
  geom_point(size = 3) +
  scale_x_discrete(breaks = periodos_reducidos1) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"), expand = c(0, 0)) +
  labs(
    title = "Cantidad de viajes en Subte a lo largo del tiempo.",
    subtitle = "Desde Enero de 2022 hasta la actualidad.",
    y = "Viajes",
    x = "Mes",
    color = "Precio pasaje\n[ARS]"
  ) +
  coord_cartesian(ylim = c(0, 30000000)) +
  original_time_theme()

ggsave(file.path(FIGURES_DIR, "05_scatter_revision_enero.png"), plot_scatter_enero, width = 12, height = 6, dpi = 300)

# 6) Scatter sueldo/tarifa parecido al original
plot_sueldo_tarifa <- SUBTE %>%
  ggplot(aes(y = cantidad, x = sueldo_tarifa_subte_pub, color = LINEA)) +
  geom_point(alpha = 0.5) +
  geom_smooth(aes(color = LINEA), se = FALSE) +
  scale_color_manual(values = COLORES_SUBTE) +
  labs(x = "Sueldo/Tarifa", y = "cantidad")

ggsave(file.path(FIGURES_DIR, "06_sueldo_tarifa_vs_cantidad.png"), plot_sueldo_tarifa, width = 10, height = 6, dpi = 300)

# Guardo el subset ya limpio para modelado visual parity
readr::write_csv(SUBTE, file.path(PROCESSED_DATA_DIR, "SUBTE_visual_parity_clean.csv"))
message("Gráficos originales-style exportados en outputs/figures/")
