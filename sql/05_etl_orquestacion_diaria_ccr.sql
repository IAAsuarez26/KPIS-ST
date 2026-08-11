-- ===============================================================================
-- ETL PASO 4: ORQUESTACIÓN Y EJECUCIÓN MAESTRA DIARIA
-- Base de Datos Destino: DW_CCR (SQL Server)
-- ===============================================================================

USE [DW_CCR];
GO

IF OBJECT_ID('fact_ccr.sp_Ejecutar_ETL_Diario_CCR', 'P') IS NOT NULL DROP PROCEDURE fact_ccr.sp_Ejecutar_ETL_Diario_CCR;
GO

CREATE PROCEDURE fact_ccr.sp_Ejecutar_ETL_Diario_CCR
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaInicio DATETIME2(0) = GETDATE();
    DECLARE @LogID INT;

    INSERT INTO staging.ETL_Log_Ejecucion (Nombre_Proceso, Paso, Fecha_Inicio, Estado)
    VALUES ('ETL_DIARIO_CCR', 'INICIO PROCESO MAESTRO', @FechaInicio, 'EN PROCESO');
    
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- -----------------------------------------------------------------------
        -- 0. REFRESCAR CAPA DE STAGING VÍA LINKED SERVER (OPCIONAL/CONDICIONAL)
        -- -----------------------------------------------------------------------
        EXEC staging.sp_ETL_Cargar_Staging_LinkedServer;

        -- -----------------------------------------------------------------------
        -- 1. POBLAR REGISTROS DEFECTO Y DIMENSIÓN TIEMPO
        -- -----------------------------------------------------------------------
        EXEC dim.sp_ETL_Garantizar_Registros_Defecto;
        EXEC dim.sp_Poblar_Dim_Tiempo '2015-01-01', '2030-12-31';

        -- -----------------------------------------------------------------------
        -- 2. SINCRONIZAR DIMENSIONES CONFORMADAS
        -- -----------------------------------------------------------------------
        EXEC dim.sp_ETL_Dim_Organizacion;
        EXEC dim.sp_ETL_Dim_Usuario_Cliente;
        EXEC dim.sp_ETL_Dim_Agente_Staff;
        EXEC dim.sp_ETL_Dim_Departamento;
        EXEC dim.sp_ETL_Dim_Equipo;
        EXEC dim.sp_ETL_Dim_Tema_Ayuda;
        EXEC dim.sp_ETL_Dim_Estado_Ticket;
        EXEC dim.sp_ETL_Dim_Prioridad_Ticket;
        EXEC dim.sp_ETL_Dim_SLA;

        -- -----------------------------------------------------------------------
        -- 3. CARGAR TABLAS DE HECHOS (FACT TABLES)
        -- -----------------------------------------------------------------------
        EXEC fact_ccr.sp_ETL_Fact_Atencion_Tickets;
        EXEC fact_ccr.sp_ETL_Fact_Eventos_Trazabilidad;
        EXEC fact_ccr.sp_ETL_Fact_Interacciones_Conversaciones;

        -- -----------------------------------------------------------------------
        -- 4. CONTEO Y AUDITORÍA DE REGISTROS PROCESADOS POR CAPA
        -- -----------------------------------------------------------------------
        DECLARE @CntStgTickets INT, @CntStgUsers INT, @CntStgOrgs INT;
        DECLARE @CntDimOrg INT, @CntDimUser INT, @CntDimStaff INT, @CntDimDept INT, @CntDimTeam INT, @CntDimTopic INT, @CntDimStatus INT, @CntDimPriority INT, @CntDimSLA INT, @CntDimTiempo INT;
        DECLARE @CntFactTickets INT, @CntFactEventos INT, @CntFactInteracciones INT;

        SELECT @CntStgTickets = COUNT(*) FROM staging.stg_ost_ticket;
        SELECT @CntStgUsers = COUNT(*) FROM staging.stg_ost_user;
        SELECT @CntStgOrgs = COUNT(*) FROM staging.stg_ost_organization;

        SELECT @CntDimOrg = COUNT(*) FROM dim.Dim_Organizacion;
        SELECT @CntDimUser = COUNT(*) FROM dim.Dim_Usuario_Cliente;
        SELECT @CntDimStaff = COUNT(*) FROM dim.Dim_Agente_Staff;
        SELECT @CntDimDept = COUNT(*) FROM dim.Dim_Departamento;
        SELECT @CntDimTeam = COUNT(*) FROM dim.Dim_Equipo;
        SELECT @CntDimTopic = COUNT(*) FROM dim.Dim_Tema_Ayuda;
        SELECT @CntDimStatus = COUNT(*) FROM dim.Dim_Estado_Ticket;
        SELECT @CntDimPriority = COUNT(*) FROM dim.Dim_Prioridad_Ticket;
        SELECT @CntDimSLA = COUNT(*) FROM dim.Dim_SLA;
        SELECT @CntDimTiempo = COUNT(*) FROM dim.Dim_Tiempo;

        SELECT @CntFactTickets = COUNT(*) FROM fact_ccr.Fact_Atencion_Tickets;
        SELECT @CntFactEventos = COUNT(*) FROM fact_ccr.Fact_Eventos_Trazabilidad;
        SELECT @CntFactInteracciones = COUNT(*) FROM fact_ccr.Fact_Interacciones_Conversaciones;

        DECLARE @FechaFin DATETIME2(0) = GETDATE();
        DECLARE @DuracionSegundos INT = DATEDIFF(second, @FechaInicio, @FechaFin);

        -- -----------------------------------------------------------------------
        -- 5. REGISTRAR ÉXITO EN EL LOG DE AUDITORÍA
        -- -----------------------------------------------------------------------
        UPDATE staging.ETL_Log_Ejecucion
        SET 
            Fecha_Fin = @FechaFin,
            Registros_Afectados = @CntFactTickets,
            Estado = 'SUCCESS',
            Paso = 'FINALIZADO EXITOSAMENTE'
        WHERE Log_ID = @LogID;

        -- -----------------------------------------------------------------------
        -- 6. IMPRIMIR RESUMEN DETALLADO DE REGISTROS PROCESADOS
        -- -----------------------------------------------------------------------
        PRINT '===================================================================';
        PRINT '        RESUMEN DE EJECUCIÓN ETL DIARIO - DW_CCR                   ';
        PRINT '===================================================================';
        PRINT 'Estado Final:            ÉXITO (SUCCESS)';
        PRINT 'Fecha de Inicio:         ' + CONVERT(VARCHAR(20), @FechaInicio, 120);
        PRINT 'Fecha de Finalización:   ' + CONVERT(VARCHAR(20), @FechaFin, 120);
        PRINT 'Duración Total:          ' + CAST(@DuracionSegundos AS VARCHAR) + ' segundo(s)';
        PRINT '-------------------------------------------------------------------';
        PRINT 'CAPA STAGING (ORIGEN MYSQL):';
        PRINT '  - Tickets Ingestados:       ' + CAST(@CntStgTickets AS VARCHAR);
        PRINT '  - Usuarios Ingestados:      ' + CAST(@CntStgUsers AS VARCHAR);
        PRINT '  - Organizaciones Ingestadas:' + CAST(@CntStgOrgs AS VARCHAR);
        PRINT '-------------------------------------------------------------------';
        PRINT 'CAPA DE DIMENSIONES (MODELO OLAP):';
        PRINT '  - Dim_Tiempo:               ' + CAST(@CntDimTiempo AS VARCHAR);
        PRINT '  - Dim_Organizacion:         ' + CAST(@CntDimOrg AS VARCHAR);
        PRINT '  - Dim_Usuario_Cliente:      ' + CAST(@CntDimUser AS VARCHAR);
        PRINT '  - Dim_Agente_Staff:         ' + CAST(@CntDimStaff AS VARCHAR);
        PRINT '  - Dim_Departamento:         ' + CAST(@CntDimDept AS VARCHAR);
        PRINT '  - Dim_Equipo:               ' + CAST(@CntDimTeam AS VARCHAR);
        PRINT '  - Dim_Tema_Ayuda:           ' + CAST(@CntDimTopic AS VARCHAR);
        PRINT '  - Dim_Estado_Ticket:        ' + CAST(@CntDimStatus AS VARCHAR);
        PRINT '  - Dim_Prioridad_Ticket:     ' + CAST(@CntDimPriority AS VARCHAR);
        PRINT '  - Dim_SLA:                  ' + CAST(@CntDimSLA AS VARCHAR);
        PRINT '-------------------------------------------------------------------';
        PRINT 'CAPA DE HECHOS (FACT TABLES):';
        PRINT '  - Fact_Atencion_Tickets:             ' + CAST(@CntFactTickets AS VARCHAR);
        PRINT '  - Fact_Eventos_Trazabilidad:        ' + CAST(@CntFactEventos AS VARCHAR);
        PRINT '  - Fact_Interacciones_Conversaciones: ' + CAST(@CntFactInteracciones AS VARCHAR);
        PRINT '===================================================================';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        UPDATE staging.ETL_Log_Ejecucion
        SET 
            Fecha_Fin = GETDATE(),
            Estado = 'ERROR',
            Paso = 'FALLO EN PROCESO',
            Mensaje_Error = @ErrorMessage
        WHERE Log_ID = @LogID;

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

PRINT 'Procedimiento Maestro de Orquestación Diario creado exitosamente.';
GO
