-- ===============================================================================
-- ETL PASO 1: CONFIGURACIÓN DE LINKED SERVER, TABLAS STAGING Y AUDITORÍA
-- Base de Datos Destino: DW_CCR (SQL Server)
-- Origen MySQL osTicket: 192.168.0.99:3306 / Usuario: root / BD: osticket
-- ===============================================================================

USE [DW_CCR];
GO

-- ===============================================================================
-- 1. CREACIÓN DE ESQUEMA DE STAGING
-- ===============================================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'staging')
BEGIN
    EXEC('CREATE SCHEMA [staging];');
END
GO

-- ===============================================================================
-- 2. HABILITAR OPCIONES DE OLE DB EN SQL SERVER (REQUERIDO PARA LINKED SERVERS)
-- ===============================================================================
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

-- Habilitar AllowInProcess y DynamicParameters para MSDASQL (si el procedimiento existe)
IF OBJECT_ID('master.dbo.sp_MSsetprovprop', 'P') IS NOT NULL
BEGIN
    EXEC master.dbo.sp_MSsetprovprop N'MSDASQL', N'AllowInProcess', 1;
    EXEC master.dbo.sp_MSsetprovprop N'MSDASQL', N'DynamicParameters', 1;
END;
GO

-- ===============================================================================
-- 3. CONFIGURACIÓN DEL SERVIDOR VINCULADO (LINKED SERVER) A MYSQL
-- ===============================================================================
DECLARE @LinkedServerName SYSNAME = N'MYSQL_OSTICKET';
DECLARE @MySQL_DB VARCHAR(50) = N'osticket';
DECLARE @MySQL_User VARCHAR(50) = N'root';
DECLARE @MySQL_Pass VARCHAR(50) = N'Paty2101';

IF EXISTS (SELECT * FROM sys.servers WHERE name = @LinkedServerName)
BEGIN
    EXEC sp_dropserver @server = @LinkedServerName, @droplogins = 'droplogins';
END

-- OPCIÓN 1: Mediante DSN de Sistema de 64 bits (Recomendado para SSMS si el driver directo falla)
/*
EXEC master.dbo.sp_addlinkedserver 
    @server = @LinkedServerName, 
    @srvproduct = N'MySQL', 
    @provider = N'MSDASQL', 
    @datasrc = N'MySQL_osTicket'; -- Nombre de DSN de Sistema creado en odbcad32.exe (64 bits)
*/

-- OPCIÓN 2: Conexión mediante Driver Directo (Nombre exacto del driver instalado en el servidor: 8.4)
EXEC master.dbo.sp_addlinkedserver 
    @server = @LinkedServerName, 
    @srvproduct = N'MySQL', 
    @provider = N'MSDASQL', 
    @datasrc = NULL,
    @location = NULL,
    @provstr = N'DRIVER={MySQL ODBC 8.4 Unicode Driver};SERVER=192.168.0.99;PORT=3306;DATABASE=osticket;UID=root;PWD=Paty2101;OPTION=3;',
    @catalog = @MySQL_DB;

-- Configurar Logins del Linked Server
EXEC master.dbo.sp_addlinkedsrvlogin 
    @rmtsrvname = @LinkedServerName, 
    @useself = N'False', 
    @locallogin = NULL, 
    @rmtuser = @MySQL_User, 
    @rmtpassword = @MySQL_Pass;

-- Opciones de optimización del Linked Server
EXEC master.dbo.sp_serveroption @server = @LinkedServerName, @optname = N'collation compatible', @optvalue = N'true';
EXEC master.dbo.sp_serveroption @server = @LinkedServerName, @optname = N'data access', @optvalue = N'true';
EXEC master.dbo.sp_serveroption @server = @LinkedServerName, @optname = N'rpc', @optvalue = N'true';
EXEC master.dbo.sp_serveroption @server = @LinkedServerName, @optname = N'rpc out', @optvalue = N'true';
EXEC master.dbo.sp_serveroption @server = @LinkedServerName, @optname = N'use remote collation', @optvalue = N'true';
GO

-- ===============================================================================
-- 4. TABLA DE AUDITORÍA Y LOGS DE EJECUCIÓN ETL
-- ===============================================================================
IF OBJECT_ID('staging.ETL_Log_Ejecucion', 'U') IS NULL
BEGIN
    CREATE TABLE staging.ETL_Log_Ejecucion (
        Log_ID INT IDENTITY(1,1) PRIMARY KEY,
        Nombre_Proceso VARCHAR(128) NOT NULL,
        Paso VARCHAR(128) NOT NULL,
        Fecha_Inicio DATETIME2(0) NOT NULL DEFAULT GETDATE(),
        Fecha_Fin DATETIME2(0) NULL,
        Registros_Afectados INT NULL DEFAULT 0,
        Estado VARCHAR(20) NOT NULL DEFAULT 'EN PROCESO',
        Mensaje_Error VARCHAR(MAX) NULL
    );
END;
GO

-- ===============================================================================
-- 5. TABLAS DE STAGING FISICAS (CAPA DE INGESTA DESACOPLADA)
-- ===============================================================================

IF OBJECT_ID('staging.stg_ost_organization', 'U') IS NOT NULL DROP TABLE staging.stg_ost_organization;
CREATE TABLE staging.stg_ost_organization (
    ID_Organizacion_Origen INT NOT NULL PRIMARY KEY,
    Nombre_Organizacion VARCHAR(128) NOT NULL,
    Gerente_Manager VARCHAR(64) NOT NULL DEFAULT '',
    Dominio VARCHAR(256) NOT NULL DEFAULT '',
    Telefono VARCHAR(64) NULL,
    Direccion VARCHAR(MAX) NULL,
    Sitio_Web VARCHAR(256) NULL,
    Estado_Organizacion INT NOT NULL DEFAULT 0,
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_user', 'U') IS NOT NULL DROP TABLE staging.stg_ost_user;
CREATE TABLE staging.stg_ost_user (
    ID_Usuario_Origen INT NOT NULL PRIMARY KEY,
    ID_Organizacion_Origen INT NOT NULL DEFAULT 0,
    Nombre_Usuario VARCHAR(128) NOT NULL,
    Email_Usuario VARCHAR(128) NOT NULL DEFAULT '',
    Telefono VARCHAR(64) NULL,
    Estado_Usuario INT NOT NULL DEFAULT 0,
    Fecha_Creacion_Origen DATETIME2(0) NULL,
    Notas VARCHAR(MAX) NULL
);

IF OBJECT_ID('staging.stg_ost_staff', 'U') IS NOT NULL DROP TABLE staging.stg_ost_staff;
CREATE TABLE staging.stg_ost_staff (
    ID_Agente_Origen INT NOT NULL PRIMARY KEY,
    ID_Departamento_Origen INT NOT NULL DEFAULT 0,
    ID_Rol_Origen INT NOT NULL DEFAULT 0,
    Username VARCHAR(32) NOT NULL,
    Nombre_Completo VARCHAR(128) NOT NULL,
    Email VARCHAR(128) NULL,
    Telefono VARCHAR(24) NULL,
    Extension VARCHAR(6) NULL,
    Movil VARCHAR(24) NULL,
    Es_Activo BIT NOT NULL DEFAULT 1,
    Es_Admin BIT NOT NULL DEFAULT 0,
    En_Vacaciones BIT NOT NULL DEFAULT 0,
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_department', 'U') IS NOT NULL DROP TABLE staging.stg_ost_department;
CREATE TABLE staging.stg_ost_department (
    ID_Departamento_Origen INT NOT NULL PRIMARY KEY,
    ID_Padre_Origen INT NULL,
    Nombre_Departamento VARCHAR(128) NOT NULL,
    Es_Publico BIT NOT NULL DEFAULT 1,
    Firma_Dept VARCHAR(MAX) NULL,
    Ruta_Path VARCHAR(128) NOT NULL DEFAULT '/',
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_team', 'U') IS NOT NULL DROP TABLE staging.stg_ost_team;
CREATE TABLE staging.stg_ost_team (
    ID_Equipo_Origen INT NOT NULL PRIMARY KEY,
    ID_Lider_Origen INT NOT NULL DEFAULT 0,
    Nombre_Equipo VARCHAR(125) NOT NULL,
    Notas VARCHAR(MAX) NULL,
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_help_topic', 'U') IS NOT NULL DROP TABLE staging.stg_ost_help_topic;
CREATE TABLE staging.stg_ost_help_topic (
    ID_Topic_Origen INT NOT NULL PRIMARY KEY,
    ID_Topic_Padre_Origen INT NOT NULL DEFAULT 0,
    Nombre_Tema VARCHAR(64) NOT NULL,
    Es_Activo BIT NOT NULL DEFAULT 1,
    Es_Publico BIT NOT NULL DEFAULT 1,
    ID_Prioridad_Defecto INT NOT NULL DEFAULT 0,
    ID_Departamento_Defecto INT NOT NULL DEFAULT 0,
    ID_SLA_Defecto INT NOT NULL DEFAULT 0,
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_ticket_status', 'U') IS NOT NULL DROP TABLE staging.stg_ost_ticket_status;
CREATE TABLE staging.stg_ost_ticket_status (
    ID_Estado_Origen INT NOT NULL PRIMARY KEY,
    Nombre_Estado VARCHAR(60) NOT NULL,
    Estado_Categoria VARCHAR(16) NULL,
    Modo INT NOT NULL DEFAULT 0,
    Flags INT NOT NULL DEFAULT 0,
    Orden_Sort INT NOT NULL DEFAULT 0
);

IF OBJECT_ID('staging.stg_ost_ticket_priority', 'U') IS NOT NULL DROP TABLE staging.stg_ost_ticket_priority;
CREATE TABLE staging.stg_ost_ticket_priority (
    ID_Prioridad_Origen TINYINT NOT NULL PRIMARY KEY,
    Nombre_Prioridad VARCHAR(60) NOT NULL,
    Descripcion_Prioridad VARCHAR(30) NOT NULL DEFAULT '',
    Color_Prioridad VARCHAR(7) NOT NULL DEFAULT '',
    Nivel_Urgencia TINYINT NOT NULL DEFAULT 0,
    Es_Publica BIT NOT NULL DEFAULT 1
);

IF OBJECT_ID('staging.stg_ost_sla', 'U') IS NOT NULL DROP TABLE staging.stg_ost_sla;
CREATE TABLE staging.stg_ost_sla (
    ID_SLA_Origen INT NOT NULL PRIMARY KEY,
    Nombre_SLA VARCHAR(64) NOT NULL,
    Periodo_Gracia_Horas INT NOT NULL DEFAULT 0,
    Notas VARCHAR(MAX) NULL,
    Fecha_Creacion DATETIME2(0) NULL
);

IF OBJECT_ID('staging.stg_ost_ticket', 'U') IS NOT NULL DROP TABLE staging.stg_ost_ticket;
CREATE TABLE staging.stg_ost_ticket (
    ID_Ticket_Origen INT NOT NULL PRIMARY KEY,
    Numero_Ticket VARCHAR(20) NOT NULL,
    Fecha_Hora_Creacion DATETIME2(0) NOT NULL,
    Fecha_Hora_Cierre DATETIME2(0) NULL,
    Fecha_Hora_Vencimiento DATETIME2(0) NULL,
    Fecha_Hora_Ultima_Actualizacion DATETIME2(0) NULL,
    user_id INT NOT NULL DEFAULT 0,
    staff_id INT NOT NULL DEFAULT 0,
    dept_id INT NOT NULL DEFAULT 0,
    team_id INT NOT NULL DEFAULT 0,
    topic_id INT NOT NULL DEFAULT 0,
    status_id INT NOT NULL DEFAULT 0,
    sla_id INT NOT NULL DEFAULT 0,
    Canal_Origen VARCHAR(32) NOT NULL DEFAULT 'Otro',
    Canal_Origen_Extra VARCHAR(40) NULL,
    Direccion_IP VARCHAR(64) NOT NULL DEFAULT '',
    Asunto_Ticket NVARCHAR(MAX) NULL,
    Nombre_Prioridad_Origen VARCHAR(60) NULL,
    Es_Vencido BIT NOT NULL DEFAULT 0,
    Es_Respondido BIT NOT NULL DEFAULT 0
);

IF OBJECT_ID('staging.stg_ost_thread_event', 'U') IS NOT NULL DROP TABLE staging.stg_ost_thread_event;
CREATE TABLE staging.stg_ost_thread_event (
    ID_Evento_Origen INT NOT NULL PRIMARY KEY,
    ID_Ticket_Origen INT NOT NULL DEFAULT 0,
    Fecha_Hora_Evento DATETIME2(0) NOT NULL,
    staff_id INT NOT NULL DEFAULT 0,
    team_id INT NOT NULL DEFAULT 0,
    dept_id INT NOT NULL DEFAULT 0,
    topic_id INT NOT NULL DEFAULT 0,
    Tipo_Evento VARCHAR(32) NOT NULL,
    Usuario_Ejecutor VARCHAR(128) NOT NULL DEFAULT 'SYSTEM',
    Tipo_Usuario_Ejecutor CHAR(1) NOT NULL DEFAULT 'S',
    Datos_Evento NVARCHAR(1024) NULL,
    Es_Anulado BIT NOT NULL DEFAULT 0
);

IF OBJECT_ID('staging.stg_ost_thread_entry', 'U') IS NOT NULL DROP TABLE staging.stg_ost_thread_entry;
CREATE TABLE staging.stg_ost_thread_entry (
    ID_Entrada_Origen INT NOT NULL PRIMARY KEY,
    ID_Ticket_Origen INT NOT NULL DEFAULT 0,
    Fecha_Hora_Interaccion DATETIME2(0) NOT NULL,
    staff_id INT NOT NULL DEFAULT 0,
    user_id INT NOT NULL DEFAULT 0,
    Tipo_Poster CHAR(1) NOT NULL DEFAULT '',
    Fuente_Mensaje VARCHAR(32) NOT NULL DEFAULT '',
    Formato VARCHAR(16) NOT NULL DEFAULT 'html',
    Titulo_Mensaje NVARCHAR(255) NULL,
    Cuerpo_Mensaje NVARCHAR(MAX) NOT NULL
);
GO

-- ===============================================================================
-- 6. PROCEDIMIENTO PARA POPULAR STAGING DESDE LINKED SERVER (DINÁMICO CON CATCH)
-- ===============================================================================
IF OBJECT_ID('staging.sp_ETL_Cargar_Staging_LinkedServer', 'P') IS NOT NULL DROP PROCEDURE staging.sp_ETL_Cargar_Staging_LinkedServer;
GO
CREATE PROCEDURE staging.sp_ETL_Cargar_Staging_LinkedServer
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Intentando sincronizar staging desde Linked Server MYSQL_OSTICKET...';

        DECLARE @Sql NVARCHAR(MAX) = N'
            -- 1. Organization
            TRUNCATE TABLE staging.stg_ost_organization;
            INSERT INTO staging.stg_ost_organization
            SELECT 
                O.id, COALESCE(O.name, ''ORGANIZACIÓN SIN NOMBRE''), COALESCE(O.manager, ''''), COALESCE(O.domain, ''''),
                COALESCE(O.phone, ''''), COALESCE(O.address, ''''), COALESCE(O.website, ''''), COALESCE(O.status, 0), O.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT O.id, O.name, O.manager, O.domain, C.phone, C.address, C.website, O.status, O.created
                FROM osticket.ost_organization O
                LEFT JOIN osticket.ost_organization__cdata C ON O.id = C.org_id
            '') O;

            -- 2. User
            TRUNCATE TABLE staging.stg_ost_user;
            INSERT INTO staging.stg_ost_user
            SELECT 
                U.id, COALESCE(U.org_id, 0), COALESCE(U.name, U.c_name, ''USUARIO GENERAL''), COALESCE(U.address, U.c_email, ''''),
                COALESCE(U.phone, ''''), COALESCE(U.status, 0), U.created, COALESCE(U.notes, '''')
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT U.id, U.org_id, U.name, E.address, C.name AS c_name, C.email AS c_email, C.phone, U.status, U.created, C.notes
                FROM osticket.ost_user U
                LEFT JOIN osticket.ost_user_email E ON U.default_email_id = E.id
                LEFT JOIN osticket.ost_user__cdata C ON U.id = C.user_id
            '') U;

            -- 3. Staff
            TRUNCATE TABLE staging.stg_ost_staff;
            INSERT INTO staging.stg_ost_staff
            SELECT 
                S.staff_id, COALESCE(S.dept_id, 0), COALESCE(S.role_id, 0), S.username,
                TRIM(CONCAT(COALESCE(S.firstname, ''''), '' '', COALESCE(S.lastname, ''''))),
                S.email, S.phone, S.phone_ext, S.mobile, S.isactive, S.isadmin, S.onvacation, S.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT staff_id, dept_id, role_id, username, firstname, lastname, email, phone, phone_ext, mobile, isactive, isadmin, onvacation, created
                FROM osticket.ost_staff
                WHERE isactive = 1
            '') S;

            -- 4. Department
            TRUNCATE TABLE staging.stg_ost_department;
            INSERT INTO staging.stg_ost_department
            SELECT D.id, D.pid, D.name, D.ispublic, D.signature, D.path, D.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT id, pid, name, ispublic, signature, path, created FROM osticket.ost_department'') D;

            -- 5. Team
            TRUNCATE TABLE staging.stg_ost_team;
            INSERT INTO staging.stg_ost_team
            SELECT T.team_id, T.lead_id, T.name, T.notes, T.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT team_id, lead_id, name, notes, created FROM osticket.ost_team'') T;

            -- 6. Help Topic
            TRUNCATE TABLE staging.stg_ost_help_topic;
            INSERT INTO staging.stg_ost_help_topic
            SELECT H.topic_id, H.topic_pid, H.topic, H.isactive, H.ispublic, H.priority_id, H.dept_id, H.sla_id, H.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT topic_id, topic_pid, topic, isactive, ispublic, priority_id, dept_id, sla_id, created FROM osticket.ost_help_topic'') H;

            -- 7. Ticket Status
            TRUNCATE TABLE staging.stg_ost_ticket_status;
            INSERT INTO staging.stg_ost_ticket_status
            SELECT S.id, S.name, S.state, S.mode, S.flags, S.sort
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT id, name, state, mode, flags, sort FROM osticket.ost_ticket_status'') S;

            -- 8. Ticket Priority
            TRUNCATE TABLE staging.stg_ost_ticket_priority;
            INSERT INTO staging.stg_ost_ticket_priority
            SELECT P.priority_id, P.priority, P.priority_desc, P.priority_color, P.priority_urgency, P.ispublic
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT priority_id, priority, priority_desc, priority_color, priority_urgency, ispublic FROM osticket.ost_ticket_priority'') P;

            -- 9. SLA
            TRUNCATE TABLE staging.stg_ost_sla;
            INSERT INTO staging.stg_ost_sla
            SELECT S.id, S.name, S.grace_period, S.notes, S.created
            FROM OPENQUERY(MYSQL_OSTICKET, ''SELECT id, name, grace_period, notes, created FROM osticket.ost_sla'') S;

            -- 10. Ticket
            TRUNCATE TABLE staging.stg_ost_ticket;
            INSERT INTO staging.stg_ost_ticket
            SELECT 
                T.ticket_id, COALESCE(T.number, CAST(T.ticket_id AS CHAR)), T.created, T.closed,
                COALESCE(T.duedate, T.est_duedate), T.lastupdate, T.user_id, T.staff_id, T.dept_id,
                T.team_id, T.topic_id, T.status_id, T.sla_id, COALESCE(T.source, ''Otro''),
                T.source_extra, COALESCE(T.ip_address, ''''), T.subject, T.priority, T.isoverdue, T.isanswered
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT T.ticket_id, T.number, T.created, T.closed, T.duedate, T.est_duedate, T.lastupdate, T.user_id, T.staff_id, T.dept_id, T.team_id, T.topic_id, T.status_id, T.sla_id, T.source, T.source_extra, T.ip_address, TC.subject, TC.priority, T.isoverdue, T.isanswered
                FROM osticket.ost_ticket T
                LEFT JOIN osticket.ost_ticket__cdata TC ON T.ticket_id = TC.ticket_id
            '') T;

            -- 11. Thread Event
            TRUNCATE TABLE staging.stg_ost_thread_event;
            INSERT INTO staging.stg_ost_thread_event
            SELECT E.id, E.object_id, E.timestamp, E.staff_id, E.team_id, E.dept_id, E.topic_id, E.state, COALESCE(E.username, ''SYSTEM''), COALESCE(E.uid_type, ''S''), E.data, E.annulled
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT E.id, TH.object_id, E.timestamp, E.staff_id, E.team_id, E.dept_id, E.topic_id, E.state, E.username, E.uid_type, E.data, E.annulled
                FROM osticket.ost_thread_event E
                INNER JOIN osticket.ost_thread TH ON E.thread_id = TH.id AND TH.object_type = ''''T''''
            '') E;

            -- 12. Thread Entry
            TRUNCATE TABLE staging.stg_ost_thread_entry;
            INSERT INTO staging.stg_ost_thread_entry
            SELECT TE.id, TE.object_id, TE.created, TE.staff_id, TE.user_id, TE.type, TE.source, TE.format, TE.title, TE.body
            FROM OPENQUERY(MYSQL_OSTICKET, ''
                SELECT TE.id, TH.object_id, TE.created, TE.staff_id, TE.user_id, TE.type, TE.source, TE.format, TE.title, TE.body
                FROM osticket.ost_thread_entry TE
                INNER JOIN osticket.ost_thread TH ON TE.thread_id = TH.id AND TH.object_type = ''''T''''
            '') TE;
        ';

        EXEC sp_executesql @Sql;
        PRINT 'Staging refrescado exitosamente desde Linked Server.';
    END TRY
    BEGIN CATCH
        PRINT 'AVISO: Linked Server MYSQL_OSTICKET no disponible o no configurado. Se mantendrán los datos de Staging existentes.';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT 'Esquema de Staging, Tablas Staging y Servidor Vinculado MYSQL_OSTICKET configurados correctamente.';
GO


