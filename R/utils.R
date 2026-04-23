source(file.path("R", "config.R"))

suppressPackageStartupMessages({
  library(lubridate)
  library(tidyverse)
  library(scales)
  library(ggridges)
  library(modelr)
  library(zoo)
  library(broom)
})

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

assert_files_exist <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop(
      paste0(
        "Faltan estos archivos:\n- ",
        paste(missing, collapse = "\n- "),
        "\n\nCopialos a data/raw/ antes de correr el proyecto."
      ),
      call. = FALSE
    )
  }
}

clean_currency <- function(x) {
  x %>%
    as.character() %>%
    stringr::str_replace_all("\\$", "") %>%
    stringr::str_replace_all(",", "") %>%
    stringr::str_trim() %>%
    na_if("") %>%
    as.numeric()
}

breaks_every <- function(x, by = 3) {
  x[seq(1, length(x), by = by)]
}

original_boxplot_theme <- function() {
  theme(
    panel.grid.major = element_line(colour = "gray"),
    plot.background = element_rect(fill = "#FAF9F6"),
    panel.background = element_rect(fill = "#FAF9F6", colour = "grey50"),
    axis.text.y = element_text(angle = 0, hjust = 1, size = 15),
    axis.text.x = element_text(size = 15),
    axis.title = element_text(size = 15),
    title = element_text(size = 11)
  )
}

original_time_theme <- function() {
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major = element_line(colour = "gray"),
    panel.background = element_rect(fill = "white", colour = "grey50")
  )
}

load_ripte <- function(local_path = file.path(RAW_DATA_DIR, "ripte_official.csv")) {
  if (file.exists(local_path)) {
    ripte_raw <- readr::read_csv(local_path, show_col_types = FALSE)
  } else {
    ripte_raw <- readr::read_csv(RIPTE_URL, show_col_types = FALSE)
  }

  ripte_raw %>%
    transmute(
      periodomes = format(as.Date(indice_tiempo), "%Y/%m"),
      salario_promedio_privado_registrado = ripte
    )
}

load_tarifas_enriched <- function(path = file.path(RAW_DATA_DIR, "tarifas_ipc.csv")) {
  df <- readr::read_csv(path, show_col_types = FALSE) %>%
    rename(periodomes = periodo) %>%
    mutate(
      tarifa_subte_registrada = clean_currency(tarifa_plena_regt),
      tarifa_subte_no_registrada = clean_currency(tarifa_plena_regf)
    )

  ripte <- load_ripte()
  base_privado <- ripte %>% filter(periodomes == "2020/01") %>% pull(salario_promedio_privado_registrado)

  df %>%
    left_join(ripte, by = "periodomes") %>%
    mutate(
      salario_promedio_publico_registrado = base_privado * (indice_pub_registrado / 100),
      salario_promedio_privado_no_registrado = base_privado * (indice_priv_registrado_no_registrado / 100),
      salario_promedio_total = base_privado * (indice_total / 100),
      sueldo_tarifa_subte_priv = salario_promedio_privado_registrado / tarifa_subte_registrada,
      sueldo_tarifa_subte_pub = salario_promedio_publico_registrado / tarifa_subte_registrada,
      sueldo_tarifa_subte_total = salario_promedio_total / tarifa_subte_registrada
    )
}

read_sube_year <- function(path) {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    col_select = c(
      DIA_TRANSPORTE, NOMBRE_EMPRESA, LINEA, AMBA, TIPO_TRANSPORTE,
      JURISDICCION, PROVINCIA, MUNICIPIO, CANTIDAD, DATO_PRELIMINAR
    )
  )
}

prepare_base_data <- function() {
  ensure_dir(PROCESSED_DATA_DIR)

  sube_paths <- file.path(RAW_DATA_DIR, SUBE_FILES)
  assert_files_exist(c(sube_paths, file.path(RAW_DATA_DIR, "tarifas_ipc.csv")))

  Sube2020 <- read_sube_year(sube_paths[1])
  Sube2021 <- read_sube_year(sube_paths[2])
  Sube2022 <- read_sube_year(sube_paths[3])
  Sube2023 <- read_sube_year(sube_paths[4])
  Sube2024 <- read_sube_year(sube_paths[5])
  Sube2025 <- read_sube_year(sube_paths[6])

  # Replico la lógica del script original para conservar la salida visual.
  NOVIEMBRE_SUBTE_2021 <- Sube2021 %>%
    filter(
      as.Date(DIA_TRANSPORTE) >= as.Date("2021-11-01"),
      as.Date(DIA_TRANSPORTE) <= as.Date("2021-12-31"),
      TIPO_TRANSPORTE == "SUBTE",
      NOMBRE_EMPRESA == "METROVIAS"
    )

  DICIEMBRE_SUBTE_2021 <- Sube2021 %>%
    filter(
      as.Date(DIA_TRANSPORTE) >= as.Date("2021-12-01"),
      as.Date(DIA_TRANSPORTE) <= as.Date("2021-12-31"),
      TIPO_TRANSPORTE == "SUBTE",
      NOMBRE_EMPRESA == "EMOVA MOVILIDAD S.A. (ex MTV)"
    )

  Sube2021 <- anti_join(Sube2021, NOVIEMBRE_SUBTE_2021)
  Sube2021 <- anti_join(Sube2021, DICIEMBRE_SUBTE_2021)

  SUBE <- bind_rows(Sube2020, Sube2021, Sube2022, Sube2023, Sube2024, Sube2025) %>%
    filter(AMBA == "SI") %>%
    separate(DIA_TRANSPORTE, c("AÑO", "MES", "DIA"), sep = "-") %>%
    mutate(
      periodo = str_c(AÑO, "/", MES, "/", DIA),
      periodomes = str_c(AÑO, "/", MES)
    ) %>%
    select(-c(AÑO, MES, DIA, JURISDICCION, PROVINCIA, MUNICIPIO, DATO_PRELIMINAR)) %>%
    group_by(periodo, periodomes, LINEA, NOMBRE_EMPRESA, TIPO_TRANSPORTE, AMBA) %>%
    summarise(cantidad = sum(CANTIDAD, na.rm = TRUE), .groups = "drop") %>%
    mutate(
      periodo_date = as.Date(periodo),
      dia = weekdays(periodo_date),
      dia = factor(dia, levels = DAY_LEVELS),
      cantidad = as.numeric(cantidad)
    ) %>%
    filter(periodomes <= "2025/09")

  tarifas <- load_tarifas_enriched()

  SUBE <- left_join(SUBE, tarifas, by = "periodomes")

  SUBTE <- SUBE %>%
    filter(TIPO_TRANSPORTE == "SUBTE") %>%
    mutate(LINEA = factor(LINEA, levels = SUBTE_LEVELS_ALL))

  BONDI <- SUBE %>% filter(TIPO_TRANSPORTE == "COLECTIVO")
  TREN <- SUBE %>% filter(TIPO_TRANSPORTE == "TREN")

  readr::write_csv(SUBE, file.path(PROCESSED_DATA_DIR, "SUBE_enriched.csv"))
  readr::write_csv(SUBTE, file.path(PROCESSED_DATA_DIR, "SUBTE_enriched.csv"))
  readr::write_csv(BONDI, file.path(PROCESSED_DATA_DIR, "BONDI_enriched.csv"))
  readr::write_csv(TREN, file.path(PROCESSED_DATA_DIR, "TREN_enriched.csv"))
  readr::write_csv(tarifas, file.path(PROCESSED_DATA_DIR, "tarifas_enriched.csv"))

  invisible(list(SUBE = SUBE, SUBTE = SUBTE, BONDI = BONDI, TREN = TREN, tarifas = tarifas))
}
