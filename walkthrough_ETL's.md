# Walkthrough: Arquitectura DDL y ETLs Diarios Anti-Duplicados (DW_PB)

Se ha completado el diseño e implementación del ecosistema de **Base de Datos OLAP (`DW_PB`)** y la suite de **Procedimientos Almacenados ETL de ejecución diaria** para la extracción desde la base transaccional Microsoft Dynamics GP (`PB` / [script-PB.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/script-PB.sql)).

---

## 📂 Archivos SQL Creados en el Proyecto

Todos los scripts han sido generados en el directorio [sql/](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql):

| Archivo SQL | Descripción / Propósito |
| :--- | :--- |
| 1. [01_ddl_dw_pb.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql/01_ddl_dw_pb.sql) | DDL completo para la creación de la BD `DW_PB`, 9 esquemas, 10 dimensiones y 11 tablas de hechos (8 Data Marts). |
| 2. [02_etl_staging_schemas.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql/02_etl_staging_schemas.sql) | Creación del esquema `stg`, la tabla de auditoría `stg.Control_Cargas_ETL` y el procedimiento de registro de logs. |
| 3. [03_etl_dimensiones.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql/03_etl_dimensiones.sql) | Procedimientos `MERGE` (SCD1) para la carga y actualización de todas las dimensiones conformadas sin duplicados. |
| 4. [04_etl_fact_tables.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql/04_etl_fact_tables.sql) | Procedimientos `MERGE` / `UPSERT` para la carga de hechos en los Data Marts (incluyendo la entrega de facturas de `PB000500`). |
| 5. [05_etl_orquestacion_diaria.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/Datawarehouse/sql/05_etl_orquestacion_diaria.sql) | Procedimiento Maestro `dbo.sp_ETL_Ejecutar_Carga_Diaria` con control de errores `TRY...CATCH` para ejecución diaria. |

---

## 🛡️ Mecanismo Anti-Duplicados y Prevención de Conflictos en MERGE

Para prevenir el error de SQL Server `The MERGE statement attempted to UPDATE or DELETE the same row more than once`, cada procedimiento ETL implementa un filtro de deduplicación previa en la fuente mediante CTEs con `ROW_NUMBER()` y limpieza preventiva en el destino:

```sql
-- 1. Limpieza preventiva de duplicados en la tabla destino
WITH TargetDuplicates AS (
    SELECT 
        Venta_ID,
        ROW_NUMBER() OVER (
            PARTITION BY SOPTYPE, SOPNUMBE, LNITMSEQ 
            ORDER BY Venta_ID ASC
        ) AS RowNum
    FROM fact_ventas.Fact_Ventas_Transaccional
)
DELETE FROM TargetDuplicates WHERE RowNum > 1;

-- 2. MERGE con subconsulta deduplicada en la fuente
WITH SourceRaw AS (
    SELECT 
        H.SOPTYPE, 
        RTRIM(H.SOPNUMBE) COLLATE DATABASE_DEFAULT AS SOPNUMBE, 
        L.LNITMSEQ,
        ...,
        ROW_NUMBER() OVER (
            PARTITION BY H.SOPTYPE, RTRIM(H.SOPNUMBE) COLLATE DATABASE_DEFAULT, L.LNITMSEQ 
            ORDER BY H.DEX_ROW_ID DESC, L.DEX_ROW_ID DESC
        ) AS RowNum
    FROM PB.dbo.SOP30200 H
    INNER JOIN PB.dbo.SOP30300 L ON H.SOPTYPE = L.SOPTYPE AND H.SOPNUMBE = L.SOPNUMBE
    LEFT JOIN dim.Dim_Cliente C ON C.CUSTNMBR = RTRIM(H.CUSTNMBR) COLLATE DATABASE_DEFAULT AND C.Es_Actual = 1
    ...
)
MERGE INTO fact_ventas.Fact_Ventas_Transaccional AS Target
USING (
    SELECT * FROM SourceRaw WHERE RowNum = 1
) AS Source
ON (Target.SOPTYPE = Source.SOPTYPE AND Target.SOPNUMBE = Source.SOPNUMBE AND Target.LNITMSEQ = Source.LNITMSEQ)
WHEN MATCHED THEN
    UPDATE SET ...
WHEN NOT MATCHED THEN
    INSERT (...) VALUES (...);
```

---

## 🔑 Garantía de Integridad Referencial (Llaves Foráneas / Foreign Keys)

Para evitar errores de violación de `FOREIGN KEY` (ej. `FK__Fact_Comp__Tiemp__335592AB`):

1. **Registros por Defecto (`dim.sp_ETL_Garantizar_Registros_Defecto`):**
   Todas las tablas de dimensiones garantizan la existencia previa del registro sustituto por defecto (`Tiempo_SK = 19000101` para fechas nulas/desconocidas y `SK = 1` para dimensiones de negocio).
2. **Auto-Poblado Dinámico de Fechas de GP:**
   El procedimiento `dim.sp_ETL_Cargar_Dim_Tiempo` detecta dinámicamente cualquier fecha válida presente en las tablas de GP (`SOP30200`, `POP30100`, `POP30110`, `GL30000`, `PB000500`) y la inserta automáticamente en `dim.Dim_Tiempo` antes de que se ejecuten las cargas de hechos.

---

## ⚙️ Instrucciones para Programar la Ejecución Diaria Automática

Para automatizar la carga diaria en SQL Server:

1. Abre **SQL Server Management Studio (SSMS)**.
2. Expande el nodo **SQL Server Agent** $\rightarrow$ **Jobs** $\rightarrow$ **New Job**.
3. En la sección **Steps**, agrega un paso con el siguiente comando T-SQL:
   ```sql
   EXEC [DW_PB].[dbo].[sp_ETL_Ejecutar_Carga_Diaria] @OrigenDB = 'PB';
   ```
4. En la sección **Schedules**, programa la ejecución diaria (ejemplo: **Todos los días a las 02:00 AM**).


