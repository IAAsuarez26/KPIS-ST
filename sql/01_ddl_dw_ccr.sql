-- ===============================================================================
-- BASE DE DATOS OLAP: DW_CCR (Call Center & Ticket Resolution Data Warehouse)
-- Motor: Microsoft SQL Server (T-SQL)
-- Origen de Datos: osTicket MySQL Database (Script_CCR.sql)
-- Collation: SQL_Latin1_General_CP1_CI_AS
-- ===============================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DW_CCR')
BEGIN
    CREATE DATABASE [DW_CCR] COLLATE SQL_Latin1_General_CP1_CI_AS;
END
ELSE
BEGIN
    BEGIN TRY
        ALTER DATABASE [DW_CCR] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        ALTER DATABASE [DW_CCR] COLLATE SQL_Latin1_General_CP1_CI_AS;
        ALTER DATABASE [DW_CCR] SET MULTI_USER;
    END TRY
    BEGIN CATCH
        ALTER DATABASE [DW_CCR] SET MULTI_USER;
    END CATCH
END
GO

USE [DW_CCR];
GO

-- ===============================================================================
-- 0. ELIMINACIÓN PREVIA DE RESTRICCIONES DE CLAVE FORÁNEA (LIMPIEZA SEGURA)
-- ===============================================================================
DECLARE @sqlFK NVARCHAR(MAX) = N'';
SELECT @sqlFK += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)) + 
                 N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(13)
FROM sys.foreign_keys;
IF @sqlFK <> N'' EXEC sp_executesql @sqlFK;
GO

-- ===============================================================================
-- 1. CREACIÓN DE ESQUEMAS LÓGICOS POR CAPA
-- ===============================================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dim') EXEC('CREATE SCHEMA [dim];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_ccr') EXEC('CREATE SCHEMA [fact_ccr];');
GO

-- ===============================================================================
-- 2. ELIMINACIÓN DE TABLAS DE HECHOS (PRIMERO HECHOS, LUEGO DIMENSIONES)
-- ===============================================================================
IF OBJECT_ID('fact_ccr.Fact_Interacciones_Conversaciones', 'U') IS NOT NULL DROP TABLE fact_ccr.Fact_Interacciones_Conversaciones;
IF OBJECT_ID('fact_ccr.Fact_Eventos_Trazabilidad', 'U') IS NOT NULL DROP TABLE fact_ccr.Fact_Eventos_Trazabilidad;
IF OBJECT_ID('fact_ccr.Fact_Atencion_Tickets', 'U') IS NOT NULL DROP TABLE fact_ccr.Fact_Atencion_Tickets;
GO

-- ===============================================================================
-- 3. ELIMINACIÓN Y CREACIÓN DE DIMENSIONES CONFORMADAS
-- ===============================================================================

-- Dimensión Tiempo
IF OBJECT_ID('dim.Dim_Tiempo', 'U') IS NOT NULL DROP TABLE dim.Dim_Tiempo;
CREATE TABLE dim.Dim_Tiempo (
    Tiempo_SK INT NOT NULL PRIMARY KEY, -- Formato YYYYMMDD
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Trimestre INT NOT NULL,
    Nombre_Trimestre VARCHAR(20) NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(20) NOT NULL,
    Semana_Anio INT NOT NULL,
    Dia_Mes INT NOT NULL,
    Dia_Semana INT NOT NULL,
    Nombre_Dia_Semana VARCHAR(20) NOT NULL,
    Es_Fin_Semana BIT NOT NULL,
    Es_Feriado BIT NOT NULL DEFAULT 0
);
GO

-- Dimensión Organización (Empresa Solicitante)
IF OBJECT_ID('dim.Dim_Organizacion', 'U') IS NOT NULL DROP TABLE dim.Dim_Organizacion;
CREATE TABLE dim.Dim_Organizacion (
    Organizacion_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Organizacion_Origen INT NOT NULL UNIQUE,
    Nombre_Organizacion VARCHAR(128) NOT NULL,
    Gerente_Manager VARCHAR(64) NOT NULL DEFAULT '',
    Dominio VARCHAR(256) NOT NULL DEFAULT '',
    Telefono VARCHAR(64) NULL,
    Direccion VARCHAR(MAX) NULL,
    Sitio_Web VARCHAR(256) NULL,
    Estado_Organizacion INT NOT NULL DEFAULT 0,
    Fecha_Creacion DATETIME2(0) NULL
);
GO

-- Dimensión Usuario Cliente (Solicitante de Soporte)
IF OBJECT_ID('dim.Dim_Usuario_Cliente', 'U') IS NOT NULL DROP TABLE dim.Dim_Usuario_Cliente;
CREATE TABLE dim.Dim_Usuario_Cliente (
    Usuario_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Usuario_Origen INT NOT NULL UNIQUE,
    ID_Organizacion_Origen INT NOT NULL DEFAULT 0,
    Nombre_Usuario VARCHAR(128) NOT NULL,
    Email_Usuario VARCHAR(128) NOT NULL DEFAULT '',
    Telefono VARCHAR(64) NULL,
    Estado_Usuario INT NOT NULL DEFAULT 0,
    Fecha_Creacion_Origen DATETIME2(0) NULL,
    Notas VARCHAR(MAX) NULL
);
GO

-- Dimensión Agente Staff (Personal de Atención / Operador CCR)
IF OBJECT_ID('dim.Dim_Agente_Staff', 'U') IS NOT NULL DROP TABLE dim.Dim_Agente_Staff;
CREATE TABLE dim.Dim_Agente_Staff (
    Agente_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Agente_Origen INT NOT NULL UNIQUE,
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
GO

-- Dimensión Departamento
IF OBJECT_ID('dim.Dim_Departamento', 'U') IS NOT NULL DROP TABLE dim.Dim_Departamento;
CREATE TABLE dim.Dim_Departamento (
    Departamento_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Departamento_Origen INT NOT NULL UNIQUE,
    ID_Padre_Origen INT NULL,
    Nombre_Departamento VARCHAR(128) NOT NULL,
    Es_Publico BIT NOT NULL DEFAULT 1,
    Firma_Dept VARCHAR(MAX) NULL,
    Ruta_Path VARCHAR(128) NOT NULL DEFAULT '/',
    Fecha_Creacion DATETIME2(0) NULL
);
GO

-- Dimensión Equipo (Team)
IF OBJECT_ID('dim.Dim_Equipo', 'U') IS NOT NULL DROP TABLE dim.Dim_Equipo;
CREATE TABLE dim.Dim_Equipo (
    Equipo_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Equipo_Origen INT NOT NULL UNIQUE,
    ID_Lider_Origen INT NOT NULL DEFAULT 0,
    Nombre_Equipo VARCHAR(125) NOT NULL,
    Notas VARCHAR(MAX) NULL,
    Fecha_Creacion DATETIME2(0) NULL
);
GO

-- Dimensión Tema Ayuda (Help Topic / Categoría del Ticket)
IF OBJECT_ID('dim.Dim_Tema_Ayuda', 'U') IS NOT NULL DROP TABLE dim.Dim_Tema_Ayuda;
CREATE TABLE dim.Dim_Tema_Ayuda (
    TemaAyuda_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Topic_Origen INT NOT NULL UNIQUE,
    ID_Topic_Padre_Origen INT NOT NULL DEFAULT 0,
    Nombre_Tema VARCHAR(64) NOT NULL,
    Es_Activo BIT NOT NULL DEFAULT 1,
    Es_Publico BIT NOT NULL DEFAULT 1,
    ID_Prioridad_Defecto INT NOT NULL DEFAULT 0,
    ID_Departamento_Defecto INT NOT NULL DEFAULT 0,
    ID_SLA_Defecto INT NOT NULL DEFAULT 0,
    Fecha_Creacion DATETIME2(0) NULL
);
GO

-- Dimensión Estado Ticket
IF OBJECT_ID('dim.Dim_Estado_Ticket', 'U') IS NOT NULL DROP TABLE dim.Dim_Estado_Ticket;
CREATE TABLE dim.Dim_Estado_Ticket (
    EstadoTicket_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Estado_Origen INT NOT NULL UNIQUE,
    Nombre_Estado VARCHAR(60) NOT NULL,
    Estado_Categoria VARCHAR(16) NULL, -- open, closed, archived, deleted
    Modo INT NOT NULL DEFAULT 0,
    Flags INT NOT NULL DEFAULT 0,
    Orden_Sort INT NOT NULL DEFAULT 0
);
GO

-- Dimensión Prioridad Ticket
IF OBJECT_ID('dim.Dim_Prioridad_Ticket', 'U') IS NOT NULL DROP TABLE dim.Dim_Prioridad_Ticket;
CREATE TABLE dim.Dim_Prioridad_Ticket (
    PrioridadTicket_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Prioridad_Origen TINYINT NOT NULL UNIQUE,
    Nombre_Prioridad VARCHAR(60) NOT NULL,
    Descripcion_Prioridad VARCHAR(30) NOT NULL DEFAULT '',
    Color_Prioridad VARCHAR(7) NOT NULL DEFAULT '',
    Nivel_Urgencia TINYINT NOT NULL DEFAULT 0,
    Es_Publica BIT NOT NULL DEFAULT 1
);
GO

-- Dimensión SLA (Service Level Agreement)
IF OBJECT_ID('dim.Dim_SLA', 'U') IS NOT NULL DROP TABLE dim.Dim_SLA;
CREATE TABLE dim.Dim_SLA (
    SLA_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_SLA_Origen INT NOT NULL UNIQUE,
    Nombre_SLA VARCHAR(64) NOT NULL,
    Periodo_Gracia_Horas INT NOT NULL DEFAULT 0,
    Notas VARCHAR(MAX) NULL,
    Fecha_Creacion DATETIME2(0) NULL
);
GO

-- ===============================================================================
-- 4. CREACIÓN DE TABLAS DE HECHOS (FACT TABLES)
-- ===============================================================================

-- Fact Table 1: Atención de Tickets (Hecho Principal OLAP)
CREATE TABLE fact_ccr.Fact_Atencion_Tickets (
    Ticket_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Ticket_Origen INT NOT NULL UNIQUE,
    Numero_Ticket VARCHAR(20) NOT NULL,
    
    -- Claves Foráneas de Tiempo
    Tiempo_Creacion_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Cierre_SK INT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Vencimiento_SK INT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Ultima_Actualizacion_SK INT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    
    -- Fechas/Horas Nativas
    Fecha_Hora_Creacion DATETIME2(0) NOT NULL,
    Fecha_Hora_Cierre DATETIME2(0) NULL,
    Fecha_Hora_Vencimiento DATETIME2(0) NULL,
    Fecha_Hora_Ultima_Actualizacion DATETIME2(0) NULL,

    -- Claves Foráneas de Dimensiones
    Usuario_SK INT NOT NULL REFERENCES dim.Dim_Usuario_Cliente(Usuario_SK),
    Organizacion_SK INT NULL REFERENCES dim.Dim_Organizacion(Organizacion_SK),
    Agente_SK INT NULL REFERENCES dim.Dim_Agente_Staff(Agente_SK),
    Departamento_SK INT NOT NULL REFERENCES dim.Dim_Departamento(Departamento_SK),
    Equipo_SK INT NULL REFERENCES dim.Dim_Equipo(Equipo_SK),
    TemaAyuda_SK INT NOT NULL REFERENCES dim.Dim_Tema_Ayuda(TemaAyuda_SK),
    EstadoTicket_SK INT NOT NULL REFERENCES dim.Dim_Estado_Ticket(EstadoTicket_SK),
    PrioridadTicket_SK INT NOT NULL REFERENCES dim.Dim_Prioridad_Ticket(PrioridadTicket_SK),
    SLA_SK INT NOT NULL REFERENCES dim.Dim_SLA(SLA_SK),

    -- Atributos Degenerados
    Canal_Origen VARCHAR(32) NOT NULL DEFAULT 'Otro', -- Web, Email, Phone, API, Other
    Canal_Origen_Extra VARCHAR(40) NULL,
    Direccion_IP VARCHAR(64) NOT NULL DEFAULT '',
    Asunto_Ticket NVARCHAR(MAX) NULL,

    -- Flags Indicadores
    Es_Vencido BIT NOT NULL DEFAULT 0,
    Es_Respondido BIT NOT NULL DEFAULT 0,
    Cumplimiento_SLA BIT NOT NULL DEFAULT 1,

    -- Métricas / Medidas Calculadas
    Cantidad_Tickets INT NOT NULL DEFAULT 1,
    Tiempo_Resolucion_Minutos INT NULL,
    Tiempo_Resolucion_Horas DECIMAL(10,2) NULL,
    Tiempo_Respuesta_Horas DECIMAL(10,2) NULL,
    Dias_Hasta_Vencimiento INT NULL
);
GO

-- Fact Table 2: Eventos de Trazabilidad de Tickets (Línea de Tiempo de Cambios)
CREATE TABLE fact_ccr.Fact_Eventos_Trazabilidad (
    Evento_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Evento_Origen INT NOT NULL UNIQUE,
    Ticket_SK INT NOT NULL REFERENCES fact_ccr.Fact_Atencion_Tickets(Ticket_SK),
    
    -- Tiempo
    Tiempo_Evento_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Fecha_Hora_Evento DATETIME2(0) NOT NULL,

    -- Dimensiones en el momento del evento
    Agente_SK INT NULL REFERENCES dim.Dim_Agente_Staff(Agente_SK),
    Equipo_SK INT NULL REFERENCES dim.Dim_Equipo(Equipo_SK),
    Departamento_SK INT NULL REFERENCES dim.Dim_Departamento(Departamento_SK),
    TemaAyuda_SK INT NULL REFERENCES dim.Dim_Tema_Ayuda(TemaAyuda_SK),

    -- Atributos de Evento
    Tipo_Evento VARCHAR(32) NOT NULL, -- created, closed, reopened, assigned, transferred, overdue, edited, etc.
    Usuario_Ejecutor VARCHAR(128) NOT NULL DEFAULT 'SYSTEM',
    Tipo_Usuario_Ejecutor CHAR(1) NOT NULL DEFAULT 'S', -- S: Staff, U: User
    Datos_Evento NVARCHAR(1024) NULL, -- Cambios codificados
    Es_Anulado BIT NOT NULL DEFAULT 0,

    -- Métricas
    Cantidad_Eventos INT NOT NULL DEFAULT 1
);
GO

-- Fact Table 3: Interacciones y Conversaciones (Respuestas en el Thread)
CREATE TABLE fact_ccr.Fact_Interacciones_Conversaciones (
    Interaccion_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ID_Entrada_Origen INT NOT NULL UNIQUE,
    Ticket_SK INT NOT NULL REFERENCES fact_ccr.Fact_Atencion_Tickets(Ticket_SK),
    
    -- Tiempo
    Tiempo_Interaccion_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Fecha_Hora_Interaccion DATETIME2(0) NOT NULL,

    -- Dimensiones
    Agente_SK INT NULL REFERENCES dim.Dim_Agente_Staff(Agente_SK),
    Usuario_SK INT NULL REFERENCES dim.Dim_Usuario_Cliente(Usuario_SK),

    -- Atributos
    Tipo_Poster CHAR(1) NOT NULL DEFAULT '',
    Fuente_Mensaje VARCHAR(32) NOT NULL DEFAULT '',
    Formato VARCHAR(16) NOT NULL DEFAULT 'html',
    Titulo_Mensaje NVARCHAR(255) NULL,
    Cuerpo_Mensaje NVARCHAR(MAX) NOT NULL,
    
    -- Métricas
    Longitud_Caracteres INT NOT NULL DEFAULT 0,
    Es_Respuesta_Agente BIT NOT NULL DEFAULT 0,
    Es_Mensaje_Cliente BIT NOT NULL DEFAULT 0,
    Cantidad_Interacciones INT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 5. CREACIÓN DE ÍNDICES OPTIMIZADOS PARA CONSULTAS OLAP / POWER BI
-- ===============================================================================

-- Índices en Fact_Atencion_Tickets
CREATE NONCLUSTERED INDEX IX_FactTickets_TiempoCreacion ON fact_ccr.Fact_Atencion_Tickets(Tiempo_Creacion_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_TiempoCierre ON fact_ccr.Fact_Atencion_Tickets(Tiempo_Cierre_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Usuario ON fact_ccr.Fact_Atencion_Tickets(Usuario_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Organizacion ON fact_ccr.Fact_Atencion_Tickets(Organizacion_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Agente ON fact_ccr.Fact_Atencion_Tickets(Agente_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Departamento ON fact_ccr.Fact_Atencion_Tickets(Departamento_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Estado ON fact_ccr.Fact_Atencion_Tickets(EstadoTicket_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_Prioridad ON fact_ccr.Fact_Atencion_Tickets(PrioridadTicket_SK);
CREATE NONCLUSTERED INDEX IX_FactTickets_SLA ON fact_ccr.Fact_Atencion_Tickets(SLA_SK);

-- Índices en Fact_Eventos_Trazabilidad
CREATE NONCLUSTERED INDEX IX_FactEventos_Ticket ON fact_ccr.Fact_Eventos_Trazabilidad(Ticket_SK);
CREATE NONCLUSTERED INDEX IX_FactEventos_Tiempo ON fact_ccr.Fact_Eventos_Trazabilidad(Tiempo_Evento_SK);
CREATE NONCLUSTERED INDEX IX_FactEventos_Agente ON fact_ccr.Fact_Eventos_Trazabilidad(Agente_SK);
CREATE NONCLUSTERED INDEX IX_FactEventos_TipoEvento ON fact_ccr.Fact_Eventos_Trazabilidad(Tipo_Evento);

-- Índices en Fact_Interacciones_Conversaciones
CREATE NONCLUSTERED INDEX IX_FactInteracciones_Ticket ON fact_ccr.Fact_Interacciones_Conversaciones(Ticket_SK);
CREATE NONCLUSTERED INDEX IX_FactInteracciones_Tiempo ON fact_ccr.Fact_Interacciones_Conversaciones(Tiempo_Interaccion_SK);
CREATE NONCLUSTERED INDEX IX_FactInteracciones_Agente ON fact_ccr.Fact_Interacciones_Conversaciones(Agente_SK);
CREATE NONCLUSTERED INDEX IX_FactInteracciones_Usuario ON fact_ccr.Fact_Interacciones_Conversaciones(Usuario_SK);
GO
