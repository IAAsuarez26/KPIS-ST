-- ===============================================================================
-- ETL PASO 2: CARGA Y SINCRONIZACIÓN DE DIMENSIONES CONFORMADAS (OPENQUERY)
-- Base de Datos Destino: DW_CCR (SQL Server)
-- Origen de Datos: osTicket MySQL Database (Script_CCR.sql / MYSQL_OSTICKET)
-- ===============================================================================

USE [DW_CCR];
GO

-- -------------------------------------------------------------------------------
-- 0. Garantizar Registros por Defecto (SK = 1 / 19000101) en todas las Dimensiones
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Garantizar_Registros_Defecto', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Garantizar_Registros_Defecto;
GO
CREATE PROCEDURE dim.sp_ETL_Garantizar_Registros_Defecto
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Dim_Tiempo (SK: 19000101)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tiempo WHERE Tiempo_SK = 19000101)
    BEGIN
        INSERT INTO dim.Dim_Tiempo (
            Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes,
            Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado
        )
        VALUES (
            19000101, '1900-01-01', 1900, 1, 'Trimestre 1', 1, 'Enero',
            1, 1, 2, 'Lunes', 0, 0
        );
    END;

    -- 2. Dim_Organizacion (Organizacion_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Organizacion WHERE Organizacion_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Organizacion ON;
        INSERT INTO dim.Dim_Organizacion (Organizacion_SK, ID_Organizacion_Origen, Nombre_Organizacion) 
        VALUES (1, 0, 'ORGANIZACIÓN DESCONOCIDA / INDEPENDIENTE');
        SET IDENTITY_INSERT dim.Dim_Organizacion OFF;
    END;

    -- 3. Dim_Usuario_Cliente (Usuario_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Usuario_Cliente WHERE Usuario_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Usuario_Cliente ON;
        INSERT INTO dim.Dim_Usuario_Cliente (Usuario_SK, ID_Usuario_Origen, ID_Organizacion_Origen, Nombre_Usuario, Email_Usuario) 
        VALUES (1, 0, 0, 'USUARIO ANÓNIMO / GENERAL', 'sin_email@sistema.com');
        SET IDENTITY_INSERT dim.Dim_Usuario_Cliente OFF;
    END;

    -- 4. Dim_Agente_Staff (Agente_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Agente_Staff WHERE Agente_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Agente_Staff ON;
        INSERT INTO dim.Dim_Agente_Staff (Agente_SK, ID_Agente_Origen, Username, Nombre_Completo, Es_Activo) 
        VALUES (1, 0, 'NO_ASIGNADO', 'AGENTE SISTEMA / SIN ASIGNAR', 1);
        SET IDENTITY_INSERT dim.Dim_Agente_Staff OFF;
    END;

    -- 5. Dim_Departamento (Departamento_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Departamento WHERE Departamento_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Departamento ON;
        INSERT INTO dim.Dim_Departamento (Departamento_SK, ID_Departamento_Origen, Nombre_Departamento) 
        VALUES (1, 0, 'DEPARTAMENTO GENERAL / DESCONOCIDO');
        SET IDENTITY_INSERT dim.Dim_Departamento OFF;
    END;

    -- 6. Dim_Equipo (Equipo_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Equipo WHERE Equipo_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Equipo ON;
        INSERT INTO dim.Dim_Equipo (Equipo_SK, ID_Equipo_Origen, Nombre_Equipo) 
        VALUES (1, 0, 'EQUIPO GENERAL / SIN EQUIPO');
        SET IDENTITY_INSERT dim.Dim_Equipo OFF;
    END;

    -- 7. Dim_Tema_Ayuda (TemaAyuda_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tema_Ayuda WHERE TemaAyuda_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Tema_Ayuda ON;
        INSERT INTO dim.Dim_Tema_Ayuda (TemaAyuda_SK, ID_Topic_Origen, Nombre_Tema) 
        VALUES (1, 0, 'TEMA GENERAL / SIN CLASIFICAR');
        SET IDENTITY_INSERT dim.Dim_Tema_Ayuda OFF;
    END;

    -- 8. Dim_Estado_Ticket (EstadoTicket_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Estado_Ticket WHERE EstadoTicket_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Estado_Ticket ON;
        INSERT INTO dim.Dim_Estado_Ticket (EstadoTicket_SK, ID_Estado_Origen, Nombre_Estado, Estado_Categoria) 
        VALUES (1, 0, 'ESTADO DESCONOCIDO', 'open');
        SET IDENTITY_INSERT dim.Dim_Estado_Ticket OFF;
    END;

    -- 9. Dim_Prioridad_Ticket (PrioridadTicket_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Prioridad_Ticket WHERE PrioridadTicket_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Prioridad_Ticket ON;
        INSERT INTO dim.Dim_Prioridad_Ticket (PrioridadTicket_SK, ID_Prioridad_Origen, Nombre_Prioridad, Descripcion_Prioridad) 
        VALUES (1, 0, 'NORMAL', 'Prioridad Estándar');
        SET IDENTITY_INSERT dim.Dim_Prioridad_Ticket OFF;
    END;

    -- 10. Dim_SLA (SLA_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_SLA WHERE SLA_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_SLA ON;
        INSERT INTO dim.Dim_SLA (SLA_SK, ID_SLA_Origen, Nombre_SLA, Periodo_Gracia_Horas) 
        VALUES (1, 0, 'SLA ESTÁNDAR / SIN SLA', 0);
        SET IDENTITY_INSERT dim.Dim_SLA OFF;
    END;
END;
GO

-- -------------------------------------------------------------------------------
-- 1. Generador de Dim_Tiempo (2015-01-01 hasta 2030-12-31)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_Poblar_Dim_Tiempo', 'P') IS NOT NULL DROP PROCEDURE dim.sp_Poblar_Dim_Tiempo;
GO
CREATE PROCEDURE dim.sp_Poblar_Dim_Tiempo
    @FechaInicio DATE = '2015-01-01',
    @FechaFin DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dim.sp_ETL_Garantizar_Registros_Defecto;

    DECLARE @FechaActual DATE = @FechaInicio;

    WHILE @FechaActual <= @FechaFin
    BEGIN
        DECLARE @Tiempo_SK INT = CAST(CONVERT(VARCHAR(8), @FechaActual, 112) AS INT);

        IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tiempo WHERE Tiempo_SK = @Tiempo_SK)
        BEGIN
            INSERT INTO dim.Dim_Tiempo (
                Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes,
                Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado
            )
            VALUES (
                @Tiempo_SK,
                @FechaActual,
                YEAR(@FechaActual),
                DATEPART(quarter, @FechaActual),
                'Trimestre ' + CAST(DATEPART(quarter, @FechaActual) AS VARCHAR),
                MONTH(@FechaActual),
                DATENAME(month, @FechaActual),
                DATEPART(iso_week, @FechaActual),
                DAY(@FechaActual),
                DATEPART(weekday, @FechaActual),
                DATENAME(dw, @FechaActual),
                CASE WHEN DATEPART(dw, @FechaActual) IN (1, 7) THEN 1 ELSE 0 END,
                0
            );
        END

        SET @FechaActual = DATEADD(day, 1, @FechaActual);
    END;
END;
GO

-- -------------------------------------------------------------------------------
-- 2. Carga / Sincronización MERGE de Dim_Organizacion (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Organizacion', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Organizacion;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Organizacion
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Organizacion AS Target
    USING (
        SELECT 
            ID_Organizacion_Origen,
            Nombre_Organizacion,
            Gerente_Manager,
            Dominio,
            Telefono,
            Direccion,
            Sitio_Web,
            Estado_Organizacion,
            Fecha_Creacion
        FROM staging.stg_ost_organization
    ) AS Source
    ON (Target.ID_Organizacion_Origen = Source.ID_Organizacion_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Nombre_Organizacion = Source.Nombre_Organizacion,
            Target.Gerente_Manager = Source.Gerente_Manager,
            Target.Dominio = Source.Dominio,
            Target.Telefono = Source.Telefono,
            Target.Direccion = Source.Direccion,
            Target.Sitio_Web = Source.Sitio_Web,
            Target.Estado_Organizacion = Source.Estado_Organizacion
    WHEN NOT MATCHED THEN
        INSERT (ID_Organizacion_Origen, Nombre_Organizacion, Gerente_Manager, Dominio, Telefono, Direccion, Sitio_Web, Estado_Organizacion, Fecha_Creacion)
        VALUES (Source.ID_Organizacion_Origen, Source.Nombre_Organizacion, Source.Gerente_Manager, Source.Dominio, Source.Telefono, Source.Direccion, Source.Sitio_Web, Source.Estado_Organizacion, Source.Fecha_Creacion);
END;
GO

-- -------------------------------------------------------------------------------
-- 3. Carga / Sincronización MERGE de Dim_Usuario_Cliente (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Usuario_Cliente', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Usuario_Cliente;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Usuario_Cliente
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Usuario_Cliente AS Target
    USING (
        SELECT 
            ID_Usuario_Origen,
            ID_Organizacion_Origen,
            Nombre_Usuario,
            Email_Usuario,
            Telefono,
            Estado_Usuario,
            Fecha_Creacion_Origen,
            Notas
        FROM staging.stg_ost_user
    ) AS Source
    ON (Target.ID_Usuario_Origen = Source.ID_Usuario_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ID_Organizacion_Origen = Source.ID_Organizacion_Origen,
            Target.Nombre_Usuario = Source.Nombre_Usuario,
            Target.Email_Usuario = Source.Email_Usuario,
            Target.Telefono = Source.Telefono,
            Target.Estado_Usuario = Source.Estado_Usuario,
            Target.Notas = Source.Notas
    WHEN NOT MATCHED THEN
        INSERT (ID_Usuario_Origen, ID_Organizacion_Origen, Nombre_Usuario, Email_Usuario, Telefono, Estado_Usuario, Fecha_Creacion_Origen, Notas)
        VALUES (Source.ID_Usuario_Origen, Source.ID_Organizacion_Origen, Source.Nombre_Usuario, Source.Email_Usuario, Source.Telefono, Source.Estado_Usuario, Source.Fecha_Creacion_Origen, Source.Notas);
END;
GO

-- -------------------------------------------------------------------------------
-- 4. Carga / Sincronización MERGE de Dim_Agente_Staff (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Agente_Staff', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Agente_Staff;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Agente_Staff
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Agente_Staff AS Target
    USING (
        SELECT 
            ID_Agente_Origen,
            ID_Departamento_Origen,
            ID_Rol_Origen,
            Username,
            Nombre_Completo,
            Email,
            Telefono,
            Extension,
            Movil,
            Es_Activo,
            Es_Admin,
            En_Vacaciones,
            Fecha_Creacion
        FROM staging.stg_ost_staff
    ) AS Source
    ON (Target.ID_Agente_Origen = Source.ID_Agente_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ID_Departamento_Origen = Source.ID_Departamento_Origen,
            Target.ID_Rol_Origen = Source.ID_Rol_Origen,
            Target.Username = Source.Username,
            Target.Nombre_Completo = Source.Nombre_Completo,
            Target.Email = Source.Email,
            Target.Telefono = Source.Telefono,
            Target.Extension = Source.Extension,
            Target.Movil = Source.Movil,
            Target.Es_Activo = Source.Es_Activo,
            Target.Es_Admin = Source.Es_Admin,
            Target.En_Vacaciones = Source.En_Vacaciones
    WHEN NOT MATCHED THEN
        INSERT (ID_Agente_Origen, ID_Departamento_Origen, ID_Rol_Origen, Username, Nombre_Completo, Email, Telefono, Extension, Movil, Es_Activo, Es_Admin, En_Vacaciones, Fecha_Creacion)
        VALUES (Source.ID_Agente_Origen, Source.ID_Departamento_Origen, Source.ID_Rol_Origen, Source.Username, Source.Nombre_Completo, Source.Email, Source.Telefono, Source.Extension, Source.Movil, Source.Es_Activo, Source.Es_Admin, Source.En_Vacaciones, Source.Fecha_Creacion);
END;
GO

-- -------------------------------------------------------------------------------
-- 5. Carga / Sincronización MERGE de Dim_Departamento (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Departamento', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Departamento;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Departamento
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Departamento AS Target
    USING (
        SELECT 
            ID_Departamento_Origen,
            ID_Padre_Origen,
            Nombre_Departamento,
            Es_Publico,
            Firma_Dept,
            Ruta_Path,
            Fecha_Creacion
        FROM staging.stg_ost_department
    ) AS Source
    ON (Target.ID_Departamento_Origen = Source.ID_Departamento_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ID_Padre_Origen = Source.ID_Padre_Origen,
            Target.Nombre_Departamento = Source.Nombre_Departamento,
            Target.Es_Publico = Source.Es_Publico,
            Target.Firma_Dept = Source.Firma_Dept,
            Target.Ruta_Path = Source.Ruta_Path
    WHEN NOT MATCHED THEN
        INSERT (ID_Departamento_Origen, ID_Padre_Origen, Nombre_Departamento, Es_Publico, Firma_Dept, Ruta_Path, Fecha_Creacion)
        VALUES (Source.ID_Departamento_Origen, Source.ID_Padre_Origen, Source.Nombre_Departamento, Source.Es_Publico, Source.Firma_Dept, Source.Ruta_Path, Source.Fecha_Creacion);
END;
GO

-- -------------------------------------------------------------------------------
-- 6. Carga / Sincronización MERGE de Dim_Equipo (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Equipo', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Equipo;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Equipo
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Equipo AS Target
    USING (
        SELECT 
            ID_Equipo_Origen,
            ID_Lider_Origen,
            Nombre_Equipo,
            Notas,
            Fecha_Creacion
        FROM staging.stg_ost_team
    ) AS Source
    ON (Target.ID_Equipo_Origen = Source.ID_Equipo_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ID_Lider_Origen = Source.ID_Lider_Origen,
            Target.Nombre_Equipo = Source.Nombre_Equipo,
            Target.Notas = Source.Notas
    WHEN NOT MATCHED THEN
        INSERT (ID_Equipo_Origen, ID_Lider_Origen, Nombre_Equipo, Notas, Fecha_Creacion)
        VALUES (Source.ID_Equipo_Origen, Source.ID_Lider_Origen, Source.Nombre_Equipo, Source.Notas, Source.Fecha_Creacion);
END;
GO

-- -------------------------------------------------------------------------------
-- 7. Carga / Sincronización MERGE de Dim_Tema_Ayuda (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Tema_Ayuda', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Tema_Ayuda;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Tema_Ayuda
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Tema_Ayuda AS Target
    USING (
        SELECT 
            ID_Topic_Origen,
            ID_Topic_Padre_Origen,
            Nombre_Tema,
            Es_Activo,
            Es_Publico,
            ID_Prioridad_Defecto,
            ID_Departamento_Defecto,
            ID_SLA_Defecto,
            Fecha_Creacion
        FROM staging.stg_ost_help_topic
    ) AS Source
    ON (Target.ID_Topic_Origen = Source.ID_Topic_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ID_Topic_Padre_Origen = Source.ID_Topic_Padre_Origen,
            Target.Nombre_Tema = Source.Nombre_Tema,
            Target.Es_Activo = Source.Es_Activo,
            Target.Es_Publico = Source.Es_Publico,
            Target.ID_Prioridad_Defecto = Source.ID_Prioridad_Defecto,
            Target.ID_Departamento_Defecto = Source.ID_Departamento_Defecto,
            Target.ID_SLA_Defecto = Source.ID_SLA_Defecto
    WHEN NOT MATCHED THEN
        INSERT (ID_Topic_Origen, ID_Topic_Padre_Origen, Nombre_Tema, Es_Activo, Es_Publico, ID_Prioridad_Defecto, ID_Departamento_Defecto, ID_SLA_Defecto, Fecha_Creacion)
        VALUES (Source.ID_Topic_Origen, Source.ID_Topic_Padre_Origen, Source.Nombre_Tema, Source.Es_Activo, Source.Es_Publico, Source.ID_Prioridad_Defecto, Source.ID_Departamento_Defecto, Source.ID_SLA_Defecto, Source.Fecha_Creacion);
END;
GO

-- -------------------------------------------------------------------------------
-- 8. Carga / Sincronización MERGE de Dim_Estado_Ticket (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Estado_Ticket', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Estado_Ticket;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Estado_Ticket
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Estado_Ticket AS Target
    USING (
        SELECT 
            ID_Estado_Origen,
            Nombre_Estado,
            Estado_Categoria,
            Modo,
            Flags,
            Orden_Sort
        FROM staging.stg_ost_ticket_status
    ) AS Source
    ON (Target.ID_Estado_Origen = Source.ID_Estado_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Nombre_Estado = Source.Nombre_Estado,
            Target.Estado_Categoria = Source.Estado_Categoria,
            Target.Modo = Source.Modo,
            Target.Flags = Source.Flags,
            Target.Orden_Sort = Source.Orden_Sort
    WHEN NOT MATCHED THEN
        INSERT (ID_Estado_Origen, Nombre_Estado, Estado_Categoria, Modo, Flags, Orden_Sort)
        VALUES (Source.ID_Estado_Origen, Source.Nombre_Estado, Source.Estado_Categoria, Source.Modo, Source.Flags, Source.Orden_Sort);
END;
GO

-- -------------------------------------------------------------------------------
-- 9. Carga / Sincronización MERGE de Dim_Prioridad_Ticket (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_Prioridad_Ticket', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_Prioridad_Ticket;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_Prioridad_Ticket
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_Prioridad_Ticket AS Target
    USING (
        SELECT 
            ID_Prioridad_Origen,
            Nombre_Prioridad,
            Descripcion_Prioridad,
            Color_Prioridad,
            Nivel_Urgencia,
            Es_Publica
        FROM staging.stg_ost_ticket_priority
    ) AS Source
    ON (Target.ID_Prioridad_Origen = Source.ID_Prioridad_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Nombre_Prioridad = Source.Nombre_Prioridad,
            Target.Descripcion_Prioridad = Source.Descripcion_Prioridad,
            Target.Color_Prioridad = Source.Color_Prioridad,
            Target.Nivel_Urgencia = Source.Nivel_Urgencia,
            Target.Es_Publica = Source.Es_Publica
    WHEN NOT MATCHED THEN
        INSERT (ID_Prioridad_Origen, Nombre_Prioridad, Descripcion_Prioridad, Color_Prioridad, Nivel_Urgencia, Es_Publica)
        VALUES (Source.ID_Prioridad_Origen, Source.Nombre_Prioridad, Source.Descripcion_Prioridad, Source.Color_Prioridad, Source.Nivel_Urgencia, Source.Es_Publica);
END;
GO

-- -------------------------------------------------------------------------------
-- 10. Carga / Sincronización MERGE de Dim_SLA (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Dim_SLA', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Dim_SLA;
GO
CREATE PROCEDURE dim.sp_ETL_Dim_SLA
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO dim.Dim_SLA AS Target
    USING (
        SELECT 
            ID_SLA_Origen,
            Nombre_SLA,
            Periodo_Gracia_Horas,
            Notas,
            Fecha_Creacion
        FROM staging.stg_ost_sla
    ) AS Source
    ON (Target.ID_SLA_Origen = Source.ID_SLA_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Nombre_SLA = Source.Nombre_SLA,
            Target.Periodo_Gracia_Horas = Source.Periodo_Gracia_Horas,
            Target.Notas = Source.Notas
    WHEN NOT MATCHED THEN
        INSERT (ID_SLA_Origen, Nombre_SLA, Periodo_Gracia_Horas, Notas, Fecha_Creacion)
        VALUES (Source.ID_SLA_Origen, Source.Nombre_SLA, Source.Periodo_Gracia_Horas, Source.Notas, Source.Fecha_Creacion);
END;
GO

PRINT 'Procedimientos ETL para la Carga de Dimensiones Conformadas (Staging Layer) creados exitosamente.';
GO

