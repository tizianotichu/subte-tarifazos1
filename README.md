# 🚇 ¿Cómo afectan los tarifazos a la cantidad de pasajeros del Subte?

Este proyecto analiza el impacto de los aumentos tarifarios en el uso del Subte en el AMBA, combinando datos reales de viajes (SUBE), tarifas históricas y salarios (RIPTE).

Es una versión refactorizada de un trabajo práctico de Introducción a la Ciencia de Datos, reorganizada como proyecto de portfolio para mostrar un flujo completo de análisis de datos.

---

## 📌 Objetivo

Responder la pregunta:

> ¿Cómo impactan los aumentos de tarifas en la cantidad de pasajeros del Subte?

---

## 📊 Datos utilizados

Se integran tres fuentes principales:

* **SUBE (usos diarios)** → viajes por día, línea y empresa
* **Tarifas históricas** → tabla construida manualmente
* **RIPTE (salarios)** → para construir la variable `sueldo/tarifa`

---

## 🧹 Limpieza y preparación de datos

Antes de modelar, se aplicaron varias decisiones clave:

* Se filtra solo AMBA
* Se corrigen duplicados por cambio de concesión (Metrovías → Emova)
* Se eliminan:

  * fines de semana
  * meses con fuerte estacionalidad (enero, febrero, diciembre)
* Se excluye el período más afectado por pandemia
* Se construye la variable:

  * **`sueldo/tarifa`** → mide accesibilidad económica

---

## 📈 Análisis exploratorio (EDA)

Se analizaron patrones en los datos:

* Distribución de viajes por línea
* Diferencias entre días de la semana
* Evolución temporal del uso del Subte
* Relación entre accesibilidad (`sueldo/tarifa`) y cantidad de viajes

---

## 🤖 Modelado

Se compararon distintos modelos de regresión:

* Modelos lineales simples
* Modelos con efectos por línea
* Modelos con interacción
* Modelo polinómico

El objetivo fue entender:

* qué variables explican mejor la cantidad de viajes
* si existe una relación clara entre tarifa y demanda

---

## 📌 Resultados (resumen)

* La variable **`sueldo/tarifa`** tiene relación con la cantidad de viajes
* Existen diferencias importantes entre líneas
* El modelo con interacción permite capturar mejor el comportamiento
* El modelo polinómico mejora el ajuste, pero pierde interpretabilidad

---

## 🧠 Qué muestra este proyecto

Este proyecto no es solo modelado, también muestra:

* trabajo con datos reales (no datasets de juguete)
* limpieza y decisiones de negocio
* integración de múltiples fuentes
* análisis exploratorio
* comparación de modelos
* refactorización de código para hacerlo reproducible

---

## 📂 Estructura del proyecto

```
subte-fare-impact-portfolio/
│
├── data/
│   ├── raw/        # datos originales (no versionados completamente)
│   └── processed/  # datasets limpios
│
├── outputs/
│   ├── figures/    # gráficos
│   └── models/     # resultados de modelos
│
├── R/
│   ├── 01_prepare_data.R
│   ├── 02_visual_parity_plots.R
│   ├── 03_modeling_visual_parity.R
│   ├── config.R
│   └── utils.R
│
├── docs/
│   └── github_upload_steps.md
│
├── run_project.R
└── README.md
```

---

## ⚙️ Cómo ejecutar el proyecto

1. Clonar el repositorio
2. Colocar los archivos de SUBE en `data/raw/`
3. Ejecutar:

```r
source("run_project.R")
```

Esto:

* limpia los datos
* genera datasets procesados
* crea gráficos
* ejecuta modelos

---

## 📷 Ejemplos de visualizaciones

*(agregar acá 2–3 imágenes desde outputs/figures cuando lo subas)*

---

## 🚀 Sobre este repositorio

Este proyecto fue refactorizado a partir de un trabajo académico para:

* mejorar la legibilidad del código
* separar etapas del análisis
* hacerlo reproducible
* dejarlo listo como proyecto de portfolio

---

## 👤 Autor

Tiziano Stacchino
Estudiante de Ciencia de Datos

---

## 🔗 GitHub

*(link al repo)*

---

## 💬 Nota

El foco del proyecto es analítico y exploratorio.
No busca predecir perfectamente, sino entender el fenómeno.

---
