# Subte fare impact — visual parity version

Esta es una versión refactorizada para portfolio, pero con una prioridad distinta a la anterior:

**mantener una salida visual lo más parecida posible al TP original**, mientras se limpia la estructura del código.

## Qué cambia respecto del script original

- el código ya no está todo en un solo archivo;
- se separa en preparación, gráficos y modelado;
- se elimina la dependencia de `tabladias.csv`;
- se conserva el estilo visual original de los gráficos tanto como sea posible;
- se reconstruyen columnas salariales necesarias para que el proyecto pueda correr con los archivos actuales.

## Cómo correrlo

1. Copiá los CSV de SUBE en `data/raw/`
2. Abrí el proyecto en RStudio
3. Ejecutá:

```r
source("run_project.R")
```

## Estructura

- `R/01_prepare_data.R`: carga y limpieza base
- `R/02_visual_parity_plots.R`: gráficos parecidos al TP original
- `R/03_modeling_visual_parity.R`: modelos y gráficos de ajuste/residuos
- `outputs/figures/`: PNG exportados
- `outputs/models/`: tablas y modelos

## Nota importante

Esta versión prioriza **paridad visual** sobre “modernizar” cada gráfico.
Eso significa que varias elecciones raras del TP original se mantienen a propósito para que el resultado final se parezca más a lo que ya habías presentado.
