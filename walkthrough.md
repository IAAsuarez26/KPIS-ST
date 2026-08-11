# 💻 KPI's S&T - Portal Analítico & Dashboard DW_CCR

Se ha diseñado, verificado y desplegado en producción el **Portal Analítico Interactivo de Sistemas y Tecnología (KPI's S&T)**, alimentado por el Data Warehouse Empresarial **DW_CCR**.

---

## 🔗 Enlaces y Repositorios Oficiales

- 🌐 **Aplicación Web Desplegada (Vercel)**: [https://kpis-st-dashboard.vercel.app](https://kpis-st-dashboard.vercel.app)
- 🐙 **Repositorio Oficial en GitHub**: [https://github.com/IAAsuarez26/KPIS-ST.git](https://github.com/IAAsuarez26/KPIS-ST.git)
- 💻 **Servidor Local (Desarrollo)**: `http://localhost:8088/`

---

## 🌟 Características y Módulos de Análisis

### 1. Filtros Dinámicos e Comparativa YoY / MoM
- **Filtro por Año (2017 a 2026 e Histórico Completo)**: Permite segmentar cualquier periodo histórico cargado en el Data Warehouse.
- **Filtro por Mes (Enero a Diciembre y Todos)**: Permite aislar comportamientos estacionales o de demanda mensual.
- **Modos de Comparación Avanzados (YoY / MoM)**:
  - **YoY (Year over Year)**: Compara el año seleccionado contra el año inmediatamente anterior (ej: `2025 vs 2024`).
  - **MoM (Month over Month)**: Compara el mes seleccionado contra el mes inmediatamente anterior.
  - Recálculo en tiempo real de **insignias de variación porcentual (% vs Prev)** y **puntos porcentuales de diferencia en SLA**.

### 2. Tarjetas KPI de Alto Impacto (Glassmorphism UI)
- **Total Tickets Atendidos**: 3,157 tickets procesados con indicador dinámico de volumen.
- **Tasa de Resolución Operativa %**: 99.2% (Meta operativa: 98%).
- **Cumplimiento de SLA Global %**: 99.2% (Compromiso de nivel de servicio).
- **Tiempo Medio de Resolución (MTTR)**: ~708.6 h con desgloses históricos.
- **Backlog Activo y Tasa de Mora**: 24 tickets abiertos pendientes (0.76% tasa de mora).

### 3. Módulos de Análisis S&T Integrados
- 🎧 **Atención & KPIs DW_CCR**: Resumen ejecutivo 360°, tarjetas de impacto, curva de tendencia mensual y distribución por temas.
- 👥 **Productividad por Agente**: Desglose de carga por técnico de soporte, tickets resueltos, mora y MTTR.
- 📑 **Demanda por Categoría**: Clasificación por Software de Negocio (Dynamics GP, Accesorios, Impresoras, Correos, etc.).
- 🛡️ **Gobernanza TI & ETLs**: Auditoría de ejecución de tuberías de datos (`staging.ETL_Log_Ejecucion`).

---

## 📸 Demostración Visual del Portal en Producción

![Portal Analítico KPI's S&T DW_CCR](file:///C:/Users/asuarez/.gemini/antigravity-ide/brain/49ebf28b-5210-485e-b1cc-13fdce3a7223/main_dashboard_1786479590452.png)

---

## 🛠️ Correcciones Técnicas & Independencia del Proyecto

1. **Aislamiento e Independencia**:
   - Se verificó y auditó que este repositorio (`KPIS-ST`) no posea vinculaciones ni dependencias cruzadas con el proyecto genérico `Datawarehouse`.
   - Se corrigieron los enlaces de producción en [`README.md`](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/README.md) y la configuración de Vercel.

2. **Resolución de Error de Inicialización JS**:
   - Se corrigieron las referencias en [`dashboard_app/app.js`](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/dashboard_app/app.js) declarando los selectores del DOM (`tabButtons`, `tabContents`, `tabTitle`, etc.) y agregando salvaguardas de seguridad para evitar `ReferenceError`.
   - Los cambios fueron commiteados y desplegados automáticamente en Vercel.

---

## 🚀 Sincronización Automática con SQL Server

Para actualizar el dataset del Portal Web tras ejecutar nuevas cargas en SQL Server:

```bash
python export_dw_ccr_json.py
```
```sql
USE [DW_CCR];
GO
EXEC fact_ccr.sp_Ejecutar_ETL_Diario_CCR;
GO
```
