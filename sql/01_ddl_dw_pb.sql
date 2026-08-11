-- ===============================================================================
-- BASE DE DATOS OLAP: DW_PB
-- Motor: Microsoft SQL Server (T-SQL)
-- Origen de Datos: Microsoft Dynamics GP - PB (script-PB.sql) y DYNAMICS
-- Collation: SQL_Latin1_General_CP1_CI_AS (Compatible con Microsoft Dynamics GP)
-- ===============================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DW_PB')
BEGIN
    CREATE DATABASE [DW_PB] COLLATE SQL_Latin1_General_CP1_CI_AS;
END
ELSE
BEGIN
    BEGIN TRY
        ALTER DATABASE [DW_PB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        ALTER DATABASE [DW_PB] COLLATE SQL_Latin1_General_CP1_CI_AS;
        ALTER DATABASE [DW_PB] SET MULTI_USER;
    END TRY
    BEGIN CATCH
        -- Si hay conexiones activas que no se pueden cerrar inmediatamente, continuar en MULTI_USER
        ALTER DATABASE [DW_PB] SET MULTI_USER;
    END CATCH
END
GO

USE [DW_PB];
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
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_ventas') EXEC('CREATE SCHEMA [fact_ventas];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_compras') EXEC('CREATE SCHEMA [fact_compras];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_finanzas') EXEC('CREATE SCHEMA [fact_finanzas];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_inventario') EXEC('CREATE SCHEMA [fact_inventario];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_planificacion') EXEC('CREATE SCHEMA [fact_planificacion];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_produccion') EXEC('CREATE SCHEMA [fact_produccion];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_sistemas') EXEC('CREATE SCHEMA [fact_sistemas];');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'fact_logistica') EXEC('CREATE SCHEMA [fact_logistica];');
GO

-- ===============================================================================
-- 2. ELIMINACIÓN DE TABLAS DE HECHOS (PRIMERO HECHOS, LUEGO DIMENSIONES)
-- ===============================================================================
IF OBJECT_ID('fact_ventas.Fact_Ventas_Transaccional', 'U') IS NOT NULL DROP TABLE fact_ventas.Fact_Ventas_Transaccional;
IF OBJECT_ID('fact_compras.Fact_Compras_Ordenes', 'U') IS NOT NULL DROP TABLE fact_compras.Fact_Compras_Ordenes;
IF OBJECT_ID('fact_finanzas.Fact_Movimientos_Contables', 'U') IS NOT NULL DROP TABLE fact_finanzas.Fact_Movimientos_Contables;
IF OBJECT_ID('fact_inventario.Fact_Movimientos_Inventario', 'U') IS NOT NULL DROP TABLE fact_inventario.Fact_Movimientos_Inventario;
IF OBJECT_ID('fact_planificacion.Fact_Planificacion_MRP', 'U') IS NOT NULL DROP TABLE fact_planificacion.Fact_Planificacion_MRP;
IF OBJECT_ID('fact_produccion.Fact_Ordenes_Produccion', 'U') IS NOT NULL DROP TABLE fact_produccion.Fact_Ordenes_Produccion;
IF OBJECT_ID('fact_sistemas.Fact_Auditoria_Sistema', 'U') IS NOT NULL DROP TABLE fact_sistemas.Fact_Auditoria_Sistema;
IF OBJECT_ID('fact_logistica.Fact_Despachos_Y_Distribucion', 'U') IS NOT NULL DROP TABLE fact_logistica.Fact_Despachos_Y_Distribucion;
IF OBJECT_ID('fact_logistica.Fact_Entrega_Facturas_Cliente', 'U') IS NOT NULL DROP TABLE fact_logistica.Fact_Entrega_Facturas_Cliente;
GO

-- ===============================================================================
-- 3. ELIMINACIÓN Y CREACIÓN DE DIMENSIONES CONFORMADAS
-- ===============================================================================

-- Dimensión Tiempo
IF OBJECT_ID('dim.Dim_Tiempo', 'U') IS NOT NULL DROP TABLE dim.Dim_Tiempo;
CREATE TABLE dim.Dim_Tiempo (
    Tiempo_SK INT NOT NULL PRIMARY KEY, -- YYYYMMDD
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
    Es_Feriado BIT NOT NULL
);
GO

-- Dimensión Tasa de Cambio (Origen: DYNAMICS.dbo.MC00100 por EXGTBLID USD-VENTAS, USD-COMPRAS, USD-FINANCIERO)
IF OBJECT_ID('dim.Dim_Tasa_Cambio', 'U') IS NOT NULL DROP TABLE dim.Dim_Tasa_Cambio;
CREATE TABLE dim.Dim_Tasa_Cambio (
    TasaCambio_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Tiempo_SK INT NOT NULL UNIQUE REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Fecha DATE NOT NULL UNIQUE,
    Tasa_Ventas DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Tasa_Compras DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Tasa_Financiero DECIMAL(19,5) NOT NULL DEFAULT 1.0
);
GO

-- Dimensión Empresa (Origen: SY01500)
IF OBJECT_ID('dim.Dim_Empresa', 'U') IS NOT NULL DROP TABLE dim.Dim_Empresa;
CREATE TABLE dim.Dim_Empresa (
    Empresa_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CMPANYID SMALLINT NOT NULL UNIQUE,
    CMPNYNAM VARCHAR(65) NOT NULL,
    TAXREGNUM VARCHAR(25) NULL,
    ADDRESS1 VARCHAR(61) NULL,
    CITY VARCHAR(35) NULL,
    STATE VARCHAR(29) NULL,
    ZIPCODE VARCHAR(11) NULL,
    COUNTRY VARCHAR(61) NULL
);
GO

-- Dimensión Usuario (Origen: SY01400 / USERID)
IF OBJECT_ID('dim.Dim_Usuario', 'U') IS NOT NULL DROP TABLE dim.Dim_Usuario;
CREATE TABLE dim.Dim_Usuario (
    Usuario_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    USERID VARCHAR(15) NOT NULL UNIQUE,
    USERNAME VARCHAR(45) NOT NULL,
    USERCLASS VARCHAR(50) NULL,
    ROL VARCHAR(50) NULL
);
GO

-- Dimensión Cliente (Origen: RM00101)
IF OBJECT_ID('dim.Dim_Cliente', 'U') IS NOT NULL DROP TABLE dim.Dim_Cliente;
CREATE TABLE dim.Dim_Cliente (
    Cliente_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CUSTNMBR VARCHAR(15) NOT NULL UNIQUE,
    CUSTNAME VARCHAR(65) NOT NULL,
    CUSTCLAS VARCHAR(15) NULL,
    CPRCSTNM VARCHAR(15) NULL,
    SALSTERR VARCHAR(15) NULL,
    SLPRSNID VARCHAR(15) NULL,
    UPSZONE VARCHAR(3) NULL,
    PYMTRMID VARCHAR(21) NULL,
    SHIPMTHD VARCHAR(15) NULL,
    TAXSCHID VARCHAR(15) NULL,
    Fecha_Inicio_SCD DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Fin_SCD DATETIME NULL,
    Es_Actual BIT NOT NULL DEFAULT 1
);
GO

-- Dimensión Proveedor (Origen: PM00200)
IF OBJECT_ID('dim.Dim_Proveedor', 'U') IS NOT NULL DROP TABLE dim.Dim_Proveedor;
CREATE TABLE dim.Dim_Proveedor (
    Proveedor_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    VENDORID VARCHAR(15) NOT NULL UNIQUE,
    VENDNAME VARCHAR(65) NOT NULL,
    VNDCLTRM VARCHAR(15) NULL,
    VENDSHNM VARCHAR(15) NULL,
    PYMTRMID VARCHAR(21) NULL,
    SHIPMTHD VARCHAR(15) NULL,
    TAXSCHID VARCHAR(15) NULL,
    CURNCYID VARCHAR(15) NULL
);
GO

-- Dimensión Producto / Artículo (Origen: IV00101)
IF OBJECT_ID('dim.Dim_Producto', 'U') IS NOT NULL DROP TABLE dim.Dim_Producto;
CREATE TABLE dim.Dim_Producto (
    Producto_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ITEMNMBR VARCHAR(31) NOT NULL UNIQUE,
    ITEMDESC VARCHAR(101) NOT NULL,
    ITMCLSCD VARCHAR(15) NULL,
    UOMSCHDL VARCHAR(11) NULL,
    ITEMTYPE SMALLINT NULL,
    DECPLQTY SMALLINT NULL,
    DECPLCUR SMALLINT NULL,
    STNDCOST DECIMAL(19,5) NULL,
    CURRCOST DECIMAL(19,5) NULL
);
GO

-- Dimensión Cuenta Contable (Origen: GL00100)
IF OBJECT_ID('dim.Dim_Cuenta_Contable', 'U') IS NOT NULL DROP TABLE dim.Dim_Cuenta_Contable;
CREATE TABLE dim.Dim_Cuenta_Contable (
    Cuenta_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ACTINDX INT NOT NULL UNIQUE,
    ACTNUMST VARCHAR(129) NOT NULL,
    ACTDESCR VARCHAR(51) NOT NULL,
    ACCTTYPE SMALLINT NOT NULL,
    ACCATNUM SMALLINT NULL,
    ACCATDSC VARCHAR(51) NULL
);
GO

-- Dimensión Centro de Costo / Segmento
IF OBJECT_ID('dim.Dim_Centro_Costo', 'U') IS NOT NULL DROP TABLE dim.Dim_Centro_Costo;
CREATE TABLE dim.Dim_Centro_Costo (
    CentroCosto_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Codigo_Centro_Costo VARCHAR(15) NOT NULL UNIQUE,
    Nombre_Centro_Costo VARCHAR(50) NOT NULL,
    Departamento VARCHAR(50) NULL
);
GO

-- Dimensión Almacén / Depósito (Origen: IV00102 / LOCNCODE)
IF OBJECT_ID('dim.Dim_Almacen', 'U') IS NOT NULL DROP TABLE dim.Dim_Almacen;
CREATE TABLE dim.Dim_Almacen (
    Almacen_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LOCNCODE VARCHAR(11) NOT NULL UNIQUE,
    LOCNDSCR VARCHAR(31) NULL,
    ADDRESS1 VARCHAR(31) NULL,
    CITY VARCHAR(35) NULL,
    STATE VARCHAR(29) NULL
);
GO

-- Dimensión Método de Envío (Origen: SY04200 / SHIPMTHD)
IF OBJECT_ID('dim.Dim_Metodo_Envio', 'U') IS NOT NULL DROP TABLE dim.Dim_Metodo_Envio;
CREATE TABLE dim.Dim_Metodo_Envio (
    MetodoEnvio_SK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SHIPMTHD VARCHAR(15) NOT NULL UNIQUE,
    CARRIER VARCHAR(31) NULL,
    SHIPTYPE SMALLINT NULL
);
GO

-- ===============================================================================
-- 4. CREACIÓN DE DATA MARTS (TABLAS DE HECHOS MULTIMONEDA VEF / USD)
-- ===============================================================================

-- 4.1 DATA MART DE VENTAS
CREATE TABLE fact_ventas.Fact_Ventas_Transaccional (
    Venta_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SOPTYPE SMALLINT NOT NULL,
    SOPNUMBE VARCHAR(21) NOT NULL,
    DOCID VARCHAR(15) NULL,
    LNITMSEQ INT NOT NULL,
    Tiempo_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Cliente_SK INT NOT NULL REFERENCES dim.Dim_Cliente(Cliente_SK),
    Producto_SK INT NOT NULL REFERENCES dim.Dim_Producto(Producto_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Almacen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    Usuario_SK INT NOT NULL REFERENCES dim.Dim_Usuario(Usuario_SK),
    Cantidad DECIMAL(19,5) NOT NULL,
    Precio_Unitario_VEF DECIMAL(19,5) NOT NULL,
    Costo_Unitario_VEF DECIMAL(19,5) NOT NULL,
    Monto_Bruto_VEF DECIMAL(19,5) NOT NULL,
    Monto_Descuento_VEF DECIMAL(19,5) NOT NULL,
    Monto_Impuesto_VEF DECIMAL(19,5) NOT NULL,
    Monto_Neto_VEF DECIMAL(19,5) NOT NULL,
    Costo_Total_VEF DECIMAL(19,5) NOT NULL,
    Margen_Ganancia_VEF DECIMAL(19,5) NOT NULL,
    Tasa_Cambio_Ventas DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Monto_Neto_USD DECIMAL(19,5) NOT NULL,
    Costo_Total_USD DECIMAL(19,5) NOT NULL,
    Margen_Ganancia_USD DECIMAL(19,5) NOT NULL
);
GO

-- 4.2 DATA MART DE COMPRAS
CREATE TABLE fact_compras.Fact_Compras_Ordenes (
    Compra_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PONUMBER VARCHAR(17) NOT NULL,
    ORD INT NOT NULL,
    Tiempo_Orden_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Requerido_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Proveedor_SK INT NOT NULL REFERENCES dim.Dim_Proveedor(Proveedor_SK),
    Producto_SK INT NOT NULL REFERENCES dim.Dim_Producto(Producto_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Almacen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    Cantidad_Ordenada DECIMAL(19,5) NOT NULL,
    Cantidad_Recibida DECIMAL(19,5) NOT NULL,
    Cantidad_Cancelada DECIMAL(19,5) NOT NULL,
    Costo_Unitario_VEF DECIMAL(19,5) NOT NULL,
    Monto_Total_Orden_VEF DECIMAL(19,5) NOT NULL,
    Tasa_Cambio_Compras DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Monto_Total_Orden_USD DECIMAL(19,5) NOT NULL
);
GO

-- 4.3 DATA MART DE FINANZAS
CREATE TABLE fact_finanzas.Fact_Movimientos_Contables (
    MovimientoContable_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    JRNENTRY INT NOT NULL,
    SQNCLINE DECIMAL(19,5) NOT NULL,
    Tiempo_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Cuenta_SK INT NOT NULL REFERENCES dim.Dim_Cuenta_Contable(Cuenta_SK),
    CentroCosto_SK INT NOT NULL REFERENCES dim.Dim_Centro_Costo(CentroCosto_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Monto_Debito_VEF DECIMAL(19,5) NOT NULL,
    Monto_Credito_VEF DECIMAL(19,5) NOT NULL,
    Monto_Neto_VEF DECIMAL(19,5) NOT NULL,
    Tasa_Cambio_Financiero DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Monto_Debito_USD DECIMAL(19,5) NOT NULL,
    Monto_Credito_USD DECIMAL(19,5) NOT NULL,
    Monto_Neto_USD DECIMAL(19,5) NOT NULL,
    CURNCYID VARCHAR(15) NULL
);
GO

-- 4.4 DATA MART DE INVENTARIO
CREATE TABLE fact_inventario.Fact_Movimientos_Inventario (
    MovimientoInventario_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DOCNUMBR VARCHAR(21) NOT NULL,
    DOCTYPE SMALLINT NOT NULL,
    Tiempo_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Producto_SK INT NOT NULL REFERENCES dim.Dim_Producto(Producto_SK),
    Almacen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Cantidad_Movimiento DECIMAL(19,5) NOT NULL,
    Costo_Unitario_VEF DECIMAL(19,5) NOT NULL,
    Costo_Total_VEF DECIMAL(19,5) NOT NULL,
    Tasa_Cambio_Financiero DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Costo_Total_USD DECIMAL(19,5) NOT NULL
);
GO

-- 4.5 DATA MART DE PLANIFICACIÓN
CREATE TABLE fact_planificacion.Fact_Planificacion_MRP (
    Planificacion_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Tiempo_Plan_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Producto_SK INT NOT NULL REFERENCES dim.Dim_Producto(Producto_SK),
    Almacen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Demanda_Pronosticada DECIMAL(19,5) NOT NULL,
    Stock_Seguridad_Requerido DECIMAL(19,5) NOT NULL,
    Cantidad_Sugerida_Compra DECIMAL(19,5) NOT NULL,
    Cantidad_Sugerida_Produccion DECIMAL(19,5) NOT NULL
);
GO

-- 4.6 DATA MART DE PRODUCCIÓN
CREATE TABLE fact_produccion.Fact_Ordenes_Produccion (
    OrdenProduccion_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MANUFACTURING_ORDER VARCHAR(30) NOT NULL,
    Tiempo_Inicio_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Fin_SK INT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Producto_SK INT NOT NULL REFERENCES dim.Dim_Producto(Producto_SK),
    Almacen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Cantidad_Programada DECIMAL(19,5) NOT NULL,
    Cantidad_Producida DECIMAL(19,5) NOT NULL,
    Cantidad_Desechada DECIMAL(19,5) NOT NULL,
    Horas_Hombre_Estimadas DECIMAL(19,5) NOT NULL,
    Horas_Hombre_Reales DECIMAL(19,5) NOT NULL,
    Horas_Maquina_Reales DECIMAL(19,5) NOT NULL
);
GO

-- 4.7 DATA MART DE SISTEMAS
CREATE TABLE fact_sistemas.Fact_Auditoria_Sistema (
    Auditoria_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Tiempo_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Usuario_SK INT NOT NULL REFERENCES dim.Dim_Usuario(Usuario_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Tipo_Evento VARCHAR(50) NOT NULL,
    Modulo_Origen VARCHAR(30) NOT NULL,
    Pantalla_ID VARCHAR(30) NULL,
    Es_Exitoso BIT NOT NULL
);
GO

-- 4.8 DATA MART DE LOGÍSTICA Y DISTRIBUCIÓN
CREATE TABLE fact_logistica.Fact_Despachos_Y_Distribucion (
    Despacho_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SOPTYPE SMALLINT NOT NULL,
    SOPNUMBE VARCHAR(21) NOT NULL,
    Tiempo_Pedido_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Tiempo_Despacho_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),
    Cliente_SK INT NOT NULL REFERENCES dim.Dim_Cliente(Cliente_SK),
    Almacen_Origen_SK INT NOT NULL REFERENCES dim.Dim_Almacen(Almacen_SK),
    MetodoEnvio_SK INT NOT NULL REFERENCES dim.Dim_Metodo_Envio(MetodoEnvio_SK),
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Dias_Ciclo_Despacho INT NOT NULL,
    Monto_Flete_VEF DECIMAL(19,5) NOT NULL,
    Tasa_Cambio_Ventas DECIMAL(19,5) NOT NULL DEFAULT 1.0,
    Monto_Flete_USD DECIMAL(19,5) NOT NULL,
    Cumple_OTIF BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE fact_logistica.Fact_Entrega_Facturas_Cliente (
    EntregaFactura_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SOPTYPE SMALLINT NOT NULL,
    SOPNUMBE VARCHAR(21) NOT NULL,
    Cliente_SK INT NOT NULL REFERENCES dim.Dim_Cliente(Cliente_SK),
    Usuario_Repartidor_SK INT NOT NULL REFERENCES dim.Dim_Usuario(Usuario_SK),
    Tiempo_Emision_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),               -- DOCDATE
    Tiempo_Entrega_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),               -- DATE1 (PB000500)
    Tiempo_Vencimiento_Original_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),  -- DUEDATE
    Tiempo_Nuevo_Vencimiento_SK INT NOT NULL REFERENCES dim.Dim_Tiempo(Tiempo_SK),     -- DocDueDate (PB000500)
    Empresa_SK INT NOT NULL REFERENCES dim.Dim_Empresa(Empresa_SK),
    Dias_Para_Entrega_Factura INT NOT NULL,             -- DATEDIFF(day, DOCDATE, DATE1)
    Dias_Desplazamiento_Vencimiento INT NOT NULL,        -- DATEDIFF(day, DUEDATE, DocDueDate)
    Es_Entrega_Con_Retraso BIT NOT NULL DEFAULT 0,
    Tasa_Cambio_Ventas DECIMAL(19,5) NOT NULL DEFAULT 1.0
);
GO

-- ===============================================================================
-- 5. ÍNDICES DE ALTO RENDIMIENTO Y UNICIDAD
-- ===============================================================================
CREATE UNIQUE INDEX UIX_Fact_Ventas_PK ON fact_ventas.Fact_Ventas_Transaccional(SOPTYPE, SOPNUMBE, LNITMSEQ);
CREATE INDEX IX_Fact_Ventas_Tiempo ON fact_ventas.Fact_Ventas_Transaccional(Tiempo_SK);
CREATE INDEX IX_Fact_Ventas_Cliente ON fact_ventas.Fact_Ventas_Transaccional(Cliente_SK);
CREATE INDEX IX_Fact_Ventas_Producto ON fact_ventas.Fact_Ventas_Transaccional(Producto_SK);

CREATE UNIQUE INDEX UIX_Fact_Compras_PK ON fact_compras.Fact_Compras_Ordenes(PONUMBER, ORD);
CREATE INDEX IX_Fact_Compras_Tiempo ON fact_compras.Fact_Compras_Ordenes(Tiempo_Orden_SK);
CREATE INDEX IX_Fact_Compras_Proveedor ON fact_compras.Fact_Compras_Ordenes(Proveedor_SK);

CREATE UNIQUE INDEX UIX_Fact_Finanzas_PK ON fact_finanzas.Fact_Movimientos_Contables(JRNENTRY, SQNCLINE);
CREATE INDEX IX_Fact_Finanzas_Tiempo ON fact_finanzas.Fact_Movimientos_Contables(Tiempo_SK);
CREATE INDEX IX_Fact_Finanzas_Cuenta ON fact_finanzas.Fact_Movimientos_Contables(Cuenta_SK);

CREATE UNIQUE INDEX UIX_Fact_Entrega_Facturas_PK ON fact_logistica.Fact_Entrega_Facturas_Cliente(SOPTYPE, SOPNUMBE);
CREATE INDEX IX_Fact_Logistica_Entrega_Cliente ON fact_logistica.Fact_Entrega_Facturas_Cliente(Cliente_SK);
CREATE INDEX IX_Fact_Logistica_Entrega_Usuario ON fact_logistica.Fact_Entrega_Facturas_Cliente(Usuario_Repartidor_SK);
CREATE INDEX IX_Fact_Logistica_Entrega_Fecha ON fact_logistica.Fact_Entrega_Facturas_Cliente(Tiempo_Entrega_SK);
GO
