-- ===============================================================================
-- ETL CAPA DE CONTROL Y AUDITORÍA: DW_PB
-- Motor: Microsoft SQL Server (T-SQL)
-- ===============================================================================

USE [DW_PB];
GO

-- 1. Crear Esquema de Staging / Control
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'stg') EXEC('CREATE SCHEMA [stg];');
GO

-- 2. Tabla de Control de Cargas ETL (Marcas de Agua y Auditoría)
IF OBJECT_ID('stg.Control_Cargas_ETL', 'U') IS NOT NULL DROP TABLE stg.Control_Cargas_ETL;
CREATE TABLE stg.Control_Cargas_ETL (
    Control_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Proceso_Nombre VARCHAR(100) NOT NULL,
    Fecha_Inicio DATETIME NOT NULL,
    Fecha_Fin DATETIME NULL,
    Fecha_Ultima_Marca_Agua DATETIME NULL,
    Registros_Insertados INT NOT NULL DEFAULT 0,
    Registros_Actualizados INT NOT NULL DEFAULT 0,
    Estado VARCHAR(20) NOT NULL DEFAULT 'EN PROCESO', -- 'EN PROCESO', 'EXITOSO', 'ERROR'
    Mensaje_Error VARCHAR(MAX) NULL
);
GO

-- 3. Procedimiento Almacenado Auxiliar para Registrar Auditoría
IF OBJECT_ID('stg.sp_ETL_Registrar_Auditoria', 'P') IS NOT NULL DROP PROCEDURE stg.sp_ETL_Registrar_Auditoria;
GO
CREATE PROCEDURE stg.sp_ETL_Registrar_Auditoria
    @Proceso_Nombre VARCHAR(100),
    @Fecha_Inicio DATETIME,
    @Fecha_Fin DATETIME,
    @Fecha_Marca_Agua DATETIME,
    @Registros_Insertados INT,
    @Registros_Actualizados INT,
    @Estado VARCHAR(20),
    @Mensaje_Error VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO stg.Control_Cargas_ETL (
        Proceso_Nombre, Fecha_Inicio, Fecha_Fin, Fecha_Ultima_Marca_Agua,
        Registros_Insertados, Registros_Actualizados, Estado, Mensaje_Error
    )
    VALUES (
        @Proceso_Nombre, @Fecha_Inicio, @Fecha_Fin, @Fecha_Marca_Agua,
        @Registros_Insertados, @Registros_Actualizados, @Estado, @Mensaje_Error
    );
END;
GO
