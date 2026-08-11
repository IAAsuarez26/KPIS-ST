# 🚀 Dashboard Web Interactivo de Inteligencia de Negocios - BD DW_CCR

Se ha diseñado, desarrollado e integrado con éxito el **Dashboard Web Interactivo** para la supervisión analítica de la base de datos **DW_CCR**, disponible localmente en **`http://localhost:8088/`**.

---

## 🌟 Características y Capacidades del Dashboard Web

### 1. Filtros Dinámicos e Interactivos en Tiempo Real
- **Filtro por Año (2017 a 2026 y Histórico Completo)**: Permite segmentar cualquier periodo histórico cargado en el Data Warehouse.
- **Filtro por Mes (Enero a Diciembre y Todos)**: Permite aislar comportamientos estacionales o de demanda mensual.
- **Modos de Comparación Avanzados (YoY / MoM)**:
  - **YoY (Year over Year)**: Compara el año seleccionado contra el año inmediatamente anterior (ej: `2025 vs 2024`).
  - **MoM (Month over Month)**: Compara el mes seleccionado contra el mes inmediatamente anterior.
  - Recálculo en tiempo real de **insignias dE variación porcentual (% vs Prev)** y **puntos porcentuales de diferencia en SLA**.

### 2. Tarjetas KPI de Alto Impacto (Glassmorphism UI)
- **Total Tickets Atendidos** (con badge dinámico YoY/MoM, ej: `+98.8% vs Prev`).
- **Tasa de Resolución Operativa %** (con badge de meta operativa, ej: `99.8%`).
- **Cumplimiento de SLA Global %** (con diferencia vs periodo anterior, ej: `99.9%`).
- **Tiempo Medio de Resolución (MTTR)** (en horas y días, ej: `282.4 h / ~11.8 días` con reducción del `50.4%` en tiempo de atención).
- **Backlog Activo y Tasa de Mora** (24 tickets abiertos pendientes).

---

## 📸 Demostración Visual del Dashboard

![Dashboard DW_CCR con Filtro 2025 y Comparativa YoY](file:///C:/Users/asuarez/.gemini/antigravity-ide/brain/a8d88e36-ba3d-466f-95dc-38b882bceaf9/dashboard_2025_yoy_1786477318748.png)

![Gráficos Interactivos de Tendencia y Carga por Agentes](file:///C:/Users/asuarez/.gemini/antigravity-ide/brain/a8d88e36-ba3d-466f-95dc-38b882bceaf9/dashboard_charts_1786477325599.png)

---

## 🛠️ Arquitectura de Sincronización Automática con la BD

Para garantizar que el Dashboard se actualice automáticamente a medida que la información cambia en SQL Server `DW_CCR`:

1. **Extractor de Datos en Tiempo Real ([`export_dw_ccr_json.py`](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/export_dw_ccr_json.py))**:
   - Conecta directamente a SQL Server `DW_CCR`, ejecuta las consultas agregadas por año/mes/agente/categoría y genera el payload en `dashboard_app/data_dw_ccr.js`.
2. **Servidor HTTP Local**:
   - Disponible en `http://localhost:8088/`. Al presionar el botón **Refrescar Datos** (icono `rotate-cw`), el Dashboard vuelve a cargar las métricas en vivo.

---

## 🌐 Cómo Acceder al Dashboard Web

Abra su navegador de preferencia y visite:
👉 **[http://localhost:8088/](http://localhost:8088/)**
