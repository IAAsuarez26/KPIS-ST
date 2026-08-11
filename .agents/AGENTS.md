# Enterprise Data Warehouse Project Guidelines & Skills Map

Este proyecto está configurado para la construcción, mantenimiento y optimización de un Data Warehouse Empresarial escalable y consistente.

## 🛠️ Habilidades Disponibles (.agents/skills)

El proyecto cuenta con 26 habilidades especializadas organizadas en 4 capas clave:

### 1. ETL / ELT & Ingesta
- `airflow-dag-patterns`: Orquestación de DAGs de producción en Apache Airflow.
- `dbt-transformation-patterns`: Modelos de transformación ELT en dbt (staging, marts, incrementales).
- `data-engineering-data-pipeline`: Arquitectura de tuberías Batch y Streaming.
- `data-engineer`: Integración de plataformas de datos y conectores cloud.
- `spark-optimization`: Procesamiento distributed y tuning en Apache Spark.
- `polars`: Transformación in-memory ultrarrápida en Python.

### 2. Modelado de Datos (Star & Snowflake Schema)
- `database-architect`: Selección de almacenamiento y arquitectura de capas DW desde cero.
- `database-design`: Principios DDL, tipos de datos, surrogate keys e integridad.
- `snowflake-development`: Desarrollo especializado en Snowflake (Dynamic Tables, Streams, Snowpark).
- `postgresql`: Diseños relacionales e integridad para capas Staging / ODS.
- `cc-skill-clickhouse-io`: Modelado OLAP columnar de alto rendimiento.

### 3. SQL, Particionamiento & Optimización
- `sql-pro`: Construcción de SQL analítico avanzado (Window Functions, CTEs, agregaciones).
- `sql-optimization-patterns`: Tuning de consultas lentas y análisis de planes de ejecución (`EXPLAIN`).
- `sql-sentinel`: Auditoría FinOps para reducir costos y consumo de créditos cloud (Snowflake, BigQuery, Redshift, Postgres).
- `database-optimizer`: Particionamiento, clustering y estrategias de rendimiento.
- `postgres-best-practices` & `postgresql-cli`: Inspección de esquemas y optimización específica en Postgres.
- `database-migrations-sql-migrations`: Migraciones DDL/DML seguras y despegues zero-downtime.

### 4. Calidad, Limpieza & Observabilidad
- `data-quality-frameworks`: Pruebas de calidad con Great Expectations, dbt tests y Data Contracts.
- `monte-carlo-analyze-root-cause`, `monte-carlo-prevent`, `monte-carlo-remediation`: Observabilidad de datos, prevención de roturas de esquemas y linaje.
- `warehouse`: Análisis y validación de provenienza de datos en el Data Warehouse.
- `lint-and-validate`: Linting y verificación estática de sintaxis SQL.
- `clean-code`: Buenas prácticas de mantenibilidad y legibilidad de código.
