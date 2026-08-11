# Plan de Corrección: Errores 7399 / 7303 en ELT de Dimensiones y Hechos (DW_CCR)

## Diagnóstico del Error

Al ejecutar los procedimientos de dimensiones (`sp_ETL_Dim_Organizacion`, `sp_ETL_Dim_Usuario_Cliente`, `sp_ETL_Dim_Agente_Staff`, etc.) se generan los siguientes errores de SQL Server:
- **Mensaje 7399, Nivel 16:** *The OLE DB provider "MSDASQL" for linked server "MYSQL_OSTICKET" reported an error.*
- **Mensaje 7303, Nivel 16:** *Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "MYSQL_OSTICKET".*

### Causa Raíz
Los procedimientos almacenados en `03_etl_dimensiones_ccr.sql` y `04_etl_fact_tables_ccr.sql` utilizan directamente `OPENQUERY(MYSQL_OSTICKET, '...')`. El proveedor OLE DB `MSDASQL` falla en SQL Server por una de las siguientes razones:
1. El driver ODBC de 64 bits **MySQL ODBC 8.0/9.0 Unicode Driver** no está instalado o su nombre exacto en Windows no coincide con la cadena de conexión de `02_etl_linked_server_ccr.sql`.
2. Las propiedades OLE DB de `MSDASQL` (`AllowInProcess = 1`) requieren **reiniciar el servicio de SQL Server** (MSSQLSERVER / SQLEXPRESS) para surtir efecto.
3. La cuenta de servicio de SQL Server no tiene permisos de lectura para el DSN de usuario/sistema o la fuente ODBC en Windows.

---

## Solución Propuesta (Arquitectura Híbrida y Robusta)

Implementaremos una estrategia doble para garantizar que el pipeline ELT funcione de forma infalible:

### Estrategia A: Arquitectura con Capa de Staging (`staging.stg_ost_*`) [Recomendado]
En lugar de depender exclusivamente de `OPENQUERY` dentro de las transformaciones de dimensiones y hechos (lo cual acopla la lógica de negocio al estado del Linked Server):
1. **Definición de Tablas Staging:** Crear tablas físicas en el esquema `staging` de `DW_CCR` para almacenar temporalmente los datos extraídos de MySQL osTicket.
2. **Carga Staging desde Python (`etl_osticket_dw.py`):** El script standalone extrae los datos de MySQL via `pymysql` y los inserta directamente en las tablas `staging.stg_ost_*` en SQL Server via `pyodbc`, **100% independiente de Linked Server y MSDASQL**.
3. **Procedimientos de Carga de Staging en T-SQL (`staging.sp_ETL_Cargar_Staging_LinkedServer`):** Permite poblar las tablas de Staging usando Linked Server si este se encuentra configurado correctamente.
4. **Transformación decoupled (`03_etl_dimensiones_ccr.sql` y `04_etl_fact_tables_ccr.sql`):** Los procedimientos `sp_ETL_Dim_*` y `sp_ETL_Fact_*` leerán de `staging.stg_ost_*`, ofreciendo ejecución ultra rápida, limpia y libre de fallos por OLE DB.

### Estrategia B: Corrección y Configuración del Linked Server `MYSQL_OSTICKET`
Proporcionar el script T-SQL corregido y la guía paso a paso para configurar el DSN de Sistema y el Linked Server en SQL Server Management Studio (SSMS).

---

## User Review Required

> [!IMPORTANT]
> **Flexibilidad de Ejecución:** Con los cambios propuestos, usted podrá ejecutar el ELT de dos maneras:
> 1. **Vía Python (`python etl_osticket_dw.py`):** Carga Staging desde MySQL y ejecuta las dimensiones/hechos en SQL Server sin depender de Linked Server.
> 2. **Vía T-SQL / SSMS (`EXEC fact_ccr.sp_Ejecutar_ETL_Diario_CCR`):** Si el Linked Server `MYSQL_OSTICKET` está activo, poblará Staging y luego actualizará dimensiones y hechos. Si no hay Linked Server, procesará los datos cargados previamente en Staging.

---

## Cambios Propuestos

### Componente 1: Configuración de Linked Server y Tablas Staging
#### [MODIFY] [02_etl_linked_server_ccr.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/sql/02_etl_linked_server_ccr.sql)
- Definición DDL de las 12 tablas en `staging`: `stg_ost_organization`, `stg_ost_user`, `stg_ost_staff`, `stg_ost_department`, `stg_ost_team`, `stg_ost_help_topic`, `stg_ost_ticket_status`, `stg_ost_ticket_priority`, `stg_ost_sla`, `stg_ost_ticket`, `stg_ost_thread_event`, `stg_ost_thread_entry`.
- Creación de procedimiento `staging.sp_ETL_Cargar_Staging_LinkedServer` con manejo de errores para poblar Staging desde Linked Server `MYSQL_OSTICKET`.
- Mejoras en la configuración T-SQL de Linked Server para soportar DSN de Sistema o Driver Directo.

### Componente 2: ELT de Dimensiones Conformadas
#### [MODIFY] [03_etl_dimensiones_ccr.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/sql/03_etl_dimensiones_ccr.sql)
- Modificar procedimientos `sp_ETL_Dim_Organizacion`, `sp_ETL_Dim_Usuario_Cliente`, `sp_ETL_Dim_Agente_Staff`, `sp_ETL_Dim_Departamento`, `sp_ETL_Dim_Equipo`, `sp_ETL_Dim_Tema_Ayuda`, `sp_ETL_Dim_Estado_Ticket`, `sp_ETL_Dim_Prioridad_Ticket`, `sp_ETL_Dim_SLA`.
- Cambiar la cláusula `USING (SELECT * FROM OPENQUERY(...))` por `USING (SELECT * FROM staging.stg_ost_...)`.

### Componente 3: ELT de Tablas de Hechos (Fact Tables)
#### [MODIFY] [04_etl_fact_tables_ccr.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/sql/04_etl_fact_tables_ccr.sql)
- Modificar `sp_ETL_Fact_Atencion_Tickets`, `sp_ETL_Fact_Eventos_Trazabilidad` y `sp_ETL_Fact_Interacciones_Conversaciones` para leer los datos de origen desde el esquema `staging`.

### Componente 4: Orquestación Maestra Daily ETL
#### [MODIFY] [05_etl_orquestacion_diaria_ccr.sql](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/sql/05_etl_orquestacion_diaria_ccr.sql)
- Incluir la llamada a `staging.sp_ETL_Cargar_Staging_LinkedServer` (intento de refresco vía Linked Server) dentro del flujo maestro `sp_Ejecutar_ETL_Diario_CCR`.

### Componente 5: Script Standalone Python
#### [MODIFY] [etl_osticket_dw.py](file:///c:/Users/asuarez/Documents/GitHub/Antigravity/KPI%27s%20S&T/etl_osticket_dw.py)
- Agregar métodos para extraer los 12 conjuntos de datos desde MySQL osTicket y cargarlos eficientemente en las tablas `staging.stg_ost_*` en SQL Server antes de invocar `fact_ccr.sp_Ejecutar_ETL_Diario_CCR`.

---

## Plan de Verificación

### Pruebas Automatizadas y de Scripts
1. Ejecución de scripts SQL en SQL Server en orden (02, 03, 04, 05).
2. Verificación de compilación limpia sin errores de sintaxis o referencias no válidas.
3. Validación de ejecución del script Python `python etl_osticket_dw.py`.

### Verificación Manual
1. Consulta a `staging.ETL_Log_Ejecucion` para validar estado `SUCCESS`.
2. Verificación del conteo de filas en dimensiones (`dim.Dim_Organizacion`, `dim.Dim_Usuario_Cliente`, etc.) y hechos (`fact_ccr.Fact_Atencion_Tickets`).
