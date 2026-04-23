PROJECT_ROOT <- "."
RAW_DATA_DIR <- file.path(PROJECT_ROOT, "data", "raw")
PROCESSED_DATA_DIR <- file.path(PROJECT_ROOT, "data", "processed")
FIGURES_DIR <- file.path(PROJECT_ROOT, "outputs", "figures")
MODELS_DIR <- file.path(PROJECT_ROOT, "outputs", "models")

SUBE_FILES <- sprintf("dat-ab-usos-%d.csv", 2020:2025)

SUBTE_LEVELS_ALL <- c(
  "LINEA_A", "LINEA_B", "LINEA SUBTE C", "LINEA SUBTE D", "LINEA SUBTE E",
  "LINEA SUBTE H", "LIN_PREMETRO", "LIN_AMARILLA_C", "LIN_VERDE_D"
)

SUBTE_LEVELS_CORE <- c(
  "LINEA_A", "LINEA_B", "LINEA SUBTE C", "LINEA SUBTE D", "LINEA SUBTE E", "LINEA SUBTE H"
)

DAY_LEVELS <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

COLORES_SUBTE <- c(
  "LINEA_A" = "#00B5DD",
  "LINEA_B" = "#FF0000",
  "LINEA SUBTE C" = "#1763AF",
  "LINEA SUBTE D" = "#05AE65",
  "LINEA SUBTE E" = "#8A2BE2",
  "LINEA SUBTE H" = "#FFDB49",
  "LIN_PREMETRO" = "#00CED1",
  "LIN_AMARILLA_C" = "#FFA07A",
  "LIN_VERDE_D" = "#ADFF2F"
)

COLORES_SUBTE_CORE <- c(
  "A" = "#00B5DD",
  "B" = "#FF0000",
  "C" = "#1763AF",
  "D" = "#05AE65",
  "E" = "#8A2BE2",
  "H" = "#FFDB49"
)

RIPTE_URL <- paste0(
  "https://infra.datos.gob.ar/catalog/sspm/dataset/158/distribution/158.1/download/",
  "remuneracion-imponible-promedio-trabajadores-estables-ripte-total-pais-pesos-serie-mensual.csv"
)
