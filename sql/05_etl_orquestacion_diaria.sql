-- ===============================================================================
-- ETL ORQUESTADOR MAESTRO DE EJECUCIÓN DIARIA: DW_PB
-- Motor: Microsoft SQL Server (T-SQL)
-- Programación Sugerida: SQL Server Agent Job (Ejecución Diaria 02:00 AM)
-- ===============================================================================

USE [DW_PB];
GO

IF OBJECT_ID('dbo.sp_ETL_Ejecutar_Carga_Diaria', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ETL_Ejecutar_Carga_Diaria;
GO
CREATE PROCEDURE dbo.sp_ETL_Ejecutar_Carga_Diaria
    @OrigenDB VARCHAR(50) = 'PB',
    @SystemDB VARCHAR(50) = 'DYNAMICS'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Fecha_Inicio DATETIME = GETDATE();
    DECLARE @Proceso VARCHAR(100) = 'ETL_Carga_Diaria_DW_PB';
    DECLARE @RegistrosIns INT = 0;
    DECLARE @RegistrosUpd INT = 0;
    
    PRINT '===============================================================================';
    PRINT 'INICIANDO PROCESO ETL DIARIO PARA DW_PB: ' + CONVERT(VARCHAR, @Fecha_Inicio, 120);
    PRINT '===============================================================================';

    BEGIN TRY
        -- ---------------------------------------------------------------------------
        -- PASO 1: CARGA DE DIMENSIONES CONFORMADAS (MERGE SCD1)
        -- ---------------------------------------------------------------------------
        PRINT '[PASO 1/3] Cargando Dimensiones Conformadas...';
        EXEC dim.sp_ETL_Cargar_Todas_Dimensiones @OrigenDB = @OrigenDB, @SystemDB = @SystemDB;
        PRINT '-> Dimensiones actualizadas correctamente.';

        -- ---------------------------------------------------------------------------
        -- PASO 2: CARGA INCREMENTAL DE TABLAS DE HECHOS (UPSERT / MERGE)
        -- ---------------------------------------------------------------------------
        PRINT '[PASO 2/3] Cargando Tablas de Hechos (Data Marts)...';
        
        PRINT '  - Cargando Data Mart de Ventas...';
        EXEC fact_ventas.sp_ETL_Cargar_Fact_Ventas @OrigenDB = @OrigenDB;

        PRINT '  - Cargando Data Mart de Compras...';
        EXEC fact_compras.sp_ETL_Cargar_Fact_Compras @OrigenDB = @OrigenDB;

        PRINT '  - Cargando Data Mart de Finanzas...';
        EXEC fact_finanzas.sp_ETL_Cargar_Fact_Finanzas @OrigenDB = @OrigenDB;

        PRINT '  - Cargando Data Mart de Logística y Distribución de Facturas (PB000500)...';
        EXEC fact_logistica.sp_ETL_Cargar_Fact_Entrega_Facturas_Cliente @OrigenDB = @OrigenDB;

        PRINT '-> Tablas de Hechos cargadas sin duplicados correctamente.';

        -- ---------------------------------------------------------------------------
        -- PASO 3: REGISTRO DE AUDITORÍA DE EJECUCIÓN EXITOSA
        -- ---------------------------------------------------------------------------
        DECLARE @Fecha_Fin DATETIME = GETDATE();
        EXEC stg.sp_ETL_Registrar_Auditoria 
            @Proceso_Nombre = @Proceso,
            @Fecha_Inicio = @Fecha_Inicio,
            @Fecha_Fin = @Fecha_Fin,
            @Fecha_Marca_Agua = @Fecha_Fin,
            @Registros_Insertados = @RegistrosIns,
            @Registros_Actualizados = @RegistrosUpd,
            @Estado = 'EXITOSO',
            @Mensaje_Error = NULL;

        PRINT '===============================================================================';
        PRINT 'PROCESO ETL DIARIO FINALIZADO CON ÉXITO: ' + CONVERT(VARCHAR, @Fecha_Fin, 120);
        PRINT '===============================================================================';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @Fecha_Error DATETIME = GETDATE();

        PRINT '!!! ERROR EN LA EJECUCIÓN DEL PROCESO ETL DIARIO !!!';
        PRINT 'Mensaje: ' + @ErrorMsg;

        EXEC stg.sp_ETL_Registrar_Auditoria 
            @Proceso_Nombre = @Proceso,
            @Fecha_Inicio = @Fecha_Inicio,
            @Fecha_Fin = @Fecha_Error,
            @Fecha_Marca_Agua = NULL,
            @Registros_Insertados = 0,
            @Registros_Actualizados = 0,
            @Estado = 'ERROR',
            @Mensaje_Error = @ErrorMsg;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO
