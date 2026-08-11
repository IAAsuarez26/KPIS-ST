-- ===============================================================================
-- ETL DIMENSIONES CONFORMADAS (SCD Type 1 / SCD Type 2 MERGE): DW_PB
-- Motor: Microsoft SQL Server (T-SQL)
-- Origen de Datos: Microsoft Dynamics GP (script-PB.sql / Base de Datos Origen [PB] y [DYNAMICS])
-- Collation Safety: COLLATE DATABASE_DEFAULT en todas las comparaciones de texto
-- ===============================================================================

USE [DW_PB];
GO

-- -------------------------------------------------------------------------------
-- 0. Garantizar Registros por Defecto (N/A / General) en todas las dimensiones
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

    -- 2. Dim_Tasa_Cambio (Tiempo_SK: 19000101)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tasa_Cambio WHERE Tiempo_SK = 19000101)
    BEGIN
        INSERT INTO dim.Dim_Tasa_Cambio (Tiempo_SK, Fecha, Tasa_Ventas, Tasa_Compras, Tasa_Financiero)
        VALUES (19000101, '1900-01-01', 1.0, 1.0, 1.0);
    END;

    -- 3. Dim_Empresa (Empresa_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Empresa WHERE Empresa_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Empresa ON;
        INSERT INTO dim.Dim_Empresa (Empresa_SK, CMPANYID, CMPNYNAM) VALUES (1, 1, 'EMPRESA GENERAL');
        SET IDENTITY_INSERT dim.Dim_Empresa OFF;
    END;

    -- 4. Dim_Usuario (Usuario_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Usuario WHERE Usuario_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Usuario ON;
        INSERT INTO dim.Dim_Usuario (Usuario_SK, USERID, USERNAME, USERCLASS, ROL) VALUES (1, 'SA', 'SYSTEM ADMIN', 'ADMIN', 'ADMINISTRADOR');
        SET IDENTITY_INSERT dim.Dim_Usuario OFF;
    END;

    -- 5. Dim_Cliente (Cliente_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Cliente WHERE Cliente_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Cliente ON;
        INSERT INTO dim.Dim_Cliente (Cliente_SK, CUSTNMBR, CUSTNAME, Fecha_Inicio_SCD, Es_Actual) 
        VALUES (1, 'DEFAULT', 'CLIENTE GENERAL / DESCONOCIDO', GETDATE(), 1);
        SET IDENTITY_INSERT dim.Dim_Cliente OFF;
    END;

    -- 6. Dim_Proveedor (Proveedor_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Proveedor WHERE Proveedor_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Proveedor ON;
        INSERT INTO dim.Dim_Proveedor (Proveedor_SK, VENDORID, VENDNAME) 
        VALUES (1, 'DEFAULT', 'PROVEEDOR GENERAL / DESCONOCIDO');
        SET IDENTITY_INSERT dim.Dim_Proveedor OFF;
    END;

    -- 7. Dim_Producto (Producto_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Producto WHERE Producto_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Producto ON;
        INSERT INTO dim.Dim_Producto (Producto_SK, ITEMNMBR, ITEMDESC) 
        VALUES (1, 'DEFAULT', 'PRODUCTO GENERAL / DESCONOCIDO');
        SET IDENTITY_INSERT dim.Dim_Producto OFF;
    END;

    -- 8. Dim_Cuenta_Contable (Cuenta_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Cuenta_Contable WHERE Cuenta_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Cuenta_Contable ON;
        INSERT INTO dim.Dim_Cuenta_Contable (Cuenta_SK, ACTINDX, ACTNUMST, ACTDESCR, ACCTTYPE) 
        VALUES (1, 1, 'DEFAULT', 'CUENTA GENERAL / DESCONOCIDA', 1);
        SET IDENTITY_INSERT dim.Dim_Cuenta_Contable OFF;
    END;

    -- 9. Dim_Centro_Costo (CentroCosto_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Centro_Costo WHERE CentroCosto_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Centro_Costo ON;
        INSERT INTO dim.Dim_Centro_Costo (CentroCosto_SK, Codigo_Centro_Costo, Nombre_Centro_Costo) 
        VALUES (1, 'DEFAULT', 'CENTRO DE COSTO GENERAL');
        SET IDENTITY_INSERT dim.Dim_Centro_Costo OFF;
    END;

    -- 10. Dim_Almacen (Almacen_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Almacen WHERE Almacen_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Almacen ON;
        INSERT INTO dim.Dim_Almacen (Almacen_SK, LOCNCODE, LOCNDSCR) 
        VALUES (1, 'DEFAULT', 'ALMACEN GENERAL / DESCONOCIDO');
        SET IDENTITY_INSERT dim.Dim_Almacen OFF;
    END;

    -- 11. Dim_Metodo_Envio (MetodoEnvio_SK: 1)
    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Metodo_Envio WHERE MetodoEnvio_SK = 1)
    BEGIN
        SET IDENTITY_INSERT dim.Dim_Metodo_Envio ON;
        INSERT INTO dim.Dim_Metodo_Envio (MetodoEnvio_SK, SHIPMTHD, CARRIER) 
        VALUES (1, 'DEFAULT', 'STANDARD');
        SET IDENTITY_INSERT dim.Dim_Metodo_Envio OFF;
    END;
END;
GO

-- -------------------------------------------------------------------------------
-- 1. Carga Dimensión Tiempo (Generador Automático de Calendario Ampliado 2000-2035)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Tiempo', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Tiempo;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Tiempo
    @OrigenDB VARCHAR(50) = 'PB',
    @Anio_Inicio INT = 2000,
    @Anio_Fin INT = 2035
AS
BEGIN
    SET NOCOUNT ON;

    -- 1.1 Garantizar el registro por defecto (19000101 / 1900-01-01)
    EXEC dim.sp_ETL_Garantizar_Registros_Defecto;

    -- 1.2 Generar calendario base 2000-2035
    DECLARE @Fecha_Actual DATE = CAST(CAST(@Anio_Inicio AS VARCHAR(4)) + '-01-01' AS DATE);
    DECLARE @Fecha_Limite DATE = CAST(CAST(@Anio_Fin AS VARCHAR(4)) + '-12-31' AS DATE);

    WHILE @Fecha_Actual <= @Fecha_Limite
    BEGIN
        DECLARE @Tiempo_SK INT = CAST(CONVERT(VARCHAR(8), @Fecha_Actual, 112) AS INT);
        
        IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tiempo WHERE Tiempo_SK = @Tiempo_SK)
        BEGIN
            INSERT INTO dim.Dim_Tiempo (
                Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes,
                Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado
            )
            VALUES (
                @Tiempo_SK,
                @Fecha_Actual,
                YEAR(@Fecha_Actual),
                DATEPART(QUARTER, @Fecha_Actual),
                'Trimestre ' + CAST(DATEPART(QUARTER, @Fecha_Actual) AS VARCHAR(1)),
                MONTH(@Fecha_Actual),
                DATENAME(MONTH, @Fecha_Actual),
                DATEPART(WEEK, @Fecha_Actual),
                DAY(@Fecha_Actual),
                DATEPART(WEEKDAY, @Fecha_Actual),
                DATENAME(WEEKDAY, @Fecha_Actual),
                CASE WHEN DATEPART(WEEKDAY, @Fecha_Actual) IN (1, 7) THEN 1 ELSE 0 END,
                0
            );
        END
        SET @Fecha_Actual = DATEADD(DAY, 1, @Fecha_Actual);
    END;

    -- 1.3 Auto-poblar dinámicamente cualquier fecha de GP presente en el origen que falte en Dim_Tiempo
    DECLARE @SQLDates NVARCHAR(MAX) = N'
    IF OBJECT_ID(''' + QUOTENAME(@OrigenDB) + N'.dbo.SOP30200'') IS NOT NULL
    BEGIN
        WITH FechasGP AS (
            SELECT CAST(DOCDATE AS DATE) AS Fecha FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.SOP30200 WHERE DOCDATE IS NOT NULL AND DOCDATE >= ''1900-01-01''
            UNION
            SELECT CAST(DOCDATE AS DATE) FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.POP30100 WHERE DOCDATE IS NOT NULL AND DOCDATE >= ''1900-01-01''
            UNION
            SELECT CAST(PRMDATE AS DATE) FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.POP30110 WHERE PRMDATE IS NOT NULL AND PRMDATE >= ''1900-01-01''
            UNION
            SELECT CAST(TRXDATE AS DATE) FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.GL30000 WHERE TRXDATE IS NOT NULL AND TRXDATE >= ''1900-01-01''
        )
        INSERT INTO dim.Dim_Tiempo (
            Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes,
            Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado
        )
        SELECT DISTINCT
            CAST(CONVERT(VARCHAR(8), Fecha, 112) AS INT) AS Tiempo_SK,
            Fecha,
            YEAR(Fecha),
            DATEPART(QUARTER, Fecha),
            ''Trimestre '' + CAST(DATEPART(QUARTER, Fecha) AS VARCHAR(1)),
            MONTH(Fecha),
            DATENAME(MONTH, Fecha),
            DATEPART(WEEK, Fecha),
            DAY(Fecha),
            DATEPART(WEEKDAY, Fecha),
            DATENAME(WEEKDAY, Fecha),
            CASE WHEN DATEPART(WEEKDAY, Fecha) IN (1, 7) THEN 1 ELSE 0 END,
            0
        FROM FechasGP
        WHERE CAST(CONVERT(VARCHAR(8), Fecha, 112) AS INT) NOT IN (SELECT Tiempo_SK FROM dim.Dim_Tiempo);
    END;';

    EXEC sp_executesql @SQLDates;
END;
GO

-- -------------------------------------------------------------------------------
-- 2. Carga Dimensión Tasa de Cambio (Con Auto-poblado y Collation Safety)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Tasa_Cambio', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Tasa_Cambio;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Tasa_Cambio
    @OrigenDB VARCHAR(50) = 'PB',
    @SystemDB VARCHAR(50) = 'DYNAMICS'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX) = N'
    IF OBJECT_ID(''' + QUOTENAME(@SystemDB) + N'.dbo.MC00100'') IS NOT NULL
    BEGIN
        -- 2.1 Auto-poblar cualquier fecha histórica de MC00100 que no exista aún en Dim_Tiempo
        INSERT INTO dim.Dim_Tiempo (
            Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes,
            Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado
        )
        SELECT DISTINCT
            CAST(CONVERT(VARCHAR(8), CAST(EXCHDATE AS DATE), 112) AS INT) AS Tiempo_SK,
            CAST(EXCHDATE AS DATE) AS Fecha,
            YEAR(CAST(EXCHDATE AS DATE)),
            DATEPART(QUARTER, CAST(EXCHDATE AS DATE)),
            ''Trimestre '' + CAST(DATEPART(QUARTER, CAST(EXCHDATE AS DATE)) AS VARCHAR(1)),
            MONTH(CAST(EXCHDATE AS DATE)),
            DATENAME(MONTH, CAST(EXCHDATE AS DATE)),
            DATEPART(WEEK, CAST(EXCHDATE AS DATE)),
            DAY(CAST(EXCHDATE AS DATE)),
            DATEPART(WEEKDAY, CAST(EXCHDATE AS DATE)),
            DATENAME(WEEKDAY, CAST(EXCHDATE AS DATE)),
            CASE WHEN DATEPART(WEEKDAY, CAST(EXCHDATE AS DATE)) IN (1, 7) THEN 1 ELSE 0 END,
            0
        FROM ' + QUOTENAME(@SystemDB) + N'.dbo.MC00100
        WHERE EXCHDATE IS NOT NULL 
          AND EXCHDATE >= ''1990-01-01''
          AND CAST(CONVERT(VARCHAR(8), CAST(EXCHDATE AS DATE), 112) AS INT) NOT IN (SELECT Tiempo_SK FROM dim.Dim_Tiempo);

        -- 2.2 Deduplicar y pivotar última tasa registrada por día para cada EXGTBLID
        WITH TasasUltimas AS (
            SELECT 
                CAST(EXCHDATE AS DATE) AS Fecha,
                RTRIM(EXGTBLID) COLLATE DATABASE_DEFAULT AS TipoTasa,
                XCHGRATE AS Tasa,
                ROW_NUMBER() OVER (
                    PARTITION BY CAST(EXCHDATE AS DATE), RTRIM(EXGTBLID) 
                    ORDER BY ISNULL(TIME1, ''23:59:59'') DESC, DEX_ROW_ID DESC
                ) AS RowNum
            FROM ' + QUOTENAME(@SystemDB) + N'.dbo.MC00100
            WHERE RTRIM(EXGTBLID) COLLATE DATABASE_DEFAULT IN (''USD-VENTAS'', ''USD-COMPRAS'', ''USD-FINANCIERO'')
              AND EXCHDATE IS NOT NULL
        ),
        TasasPivot AS (
            SELECT 
                Fecha,
                CAST(CONVERT(VARCHAR(8), Fecha, 112) AS INT) AS Tiempo_SK,
                MAX(CASE WHEN TipoTasa = ''USD-VENTAS'' THEN Tasa END) AS Tasa_Ventas,
                MAX(CASE WHEN TipoTasa = ''USD-COMPRAS'' THEN Tasa END) AS Tasa_Compras,
                MAX(CASE WHEN TipoTasa = ''USD-FINANCIERO'' THEN Tasa END) AS Tasa_Financiero
            FROM TasasUltimas
            WHERE RowNum = 1
            GROUP BY Fecha
        )
        MERGE INTO dim.Dim_Tasa_Cambio AS Target
        USING TasasPivot AS Source
        ON (Target.Fecha = Source.Fecha)
        WHEN MATCHED THEN
            UPDATE SET 
                Target.Tasa_Ventas = ISNULL(Source.Tasa_Ventas, Target.Tasa_Ventas),
                Target.Tasa_Compras = ISNULL(Source.Tasa_Compras, Target.Tasa_Compras),
                Target.Tasa_Financiero = ISNULL(Source.Tasa_Financiero, Target.Tasa_Financiero)
        WHEN NOT MATCHED THEN
            INSERT (Tiempo_SK, Fecha, Tasa_Ventas, Tasa_Compras, Tasa_Financiero)
            VALUES (
                Source.Tiempo_SK, 
                Source.Fecha, 
                ISNULL(Source.Tasa_Ventas, 1.0), 
                ISNULL(Source.Tasa_Compras, 1.0), 
                ISNULL(Source.Tasa_Financiero, 1.0)
            );
    END;';

    EXEC sp_executesql @SQL;

    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tasa_Cambio)
    BEGIN
        DECLARE @HoySK INT = CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT);
        DECLARE @HoyDate DATE = CAST(GETDATE() AS DATE);
        
        IF NOT EXISTS (SELECT 1 FROM dim.Dim_Tiempo WHERE Tiempo_SK = @HoySK)
        BEGIN
            INSERT INTO dim.Dim_Tiempo (Tiempo_SK, Fecha, Anio, Trimestre, Nombre_Trimestre, Mes, Nombre_Mes, Semana_Anio, Dia_Mes, Dia_Semana, Nombre_Dia_Semana, Es_Fin_Semana, Es_Feriado)
            VALUES (@HoySK, @HoyDate, YEAR(@HoyDate), DATEPART(QUARTER, @HoyDate), 'Trimestre ' + CAST(DATEPART(QUARTER, @HoyDate) AS VARCHAR(1)), MONTH(@HoyDate), DATENAME(MONTH, @HoyDate), DATEPART(WEEK, @HoyDate), DAY(@HoyDate), DATEPART(WEEKDAY, @HoyDate), DATENAME(WEEKDAY, @HoyDate), 0, 0);
        END

        INSERT INTO dim.Dim_Tasa_Cambio (Tiempo_SK, Fecha, Tasa_Ventas, Tasa_Compras, Tasa_Financiero)
        VALUES (@HoySK, @HoyDate, 1.0, 1.0, 1.0);
    END;
END;
GO

-- -------------------------------------------------------------------------------
-- 3. Carga Dimensión Empresa (Origen: DYNAMICS.dbo.SY01500 o fallback)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Empresa', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Empresa;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Empresa
    @OrigenDB VARCHAR(50) = 'PB',
    @SystemDB VARCHAR(50) = 'DYNAMICS'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TargetDB VARCHAR(50) = @OrigenDB;

    IF OBJECT_ID(QUOTENAME(@SystemDB) + '.dbo.SY01500') IS NOT NULL
        SET @TargetDB = @SystemDB;

    DECLARE @SQL NVARCHAR(MAX) = N'
    IF OBJECT_ID(''' + QUOTENAME(@TargetDB) + N'.dbo.SY01500'') IS NOT NULL
    BEGIN
        MERGE INTO dim.Dim_Empresa AS Target
        USING (
            SELECT 
                CMPANYID, 
                RTRIM(CMPNYNAM) COLLATE DATABASE_DEFAULT AS CMPNYNAM, 
                RTRIM(ADDRESS1) COLLATE DATABASE_DEFAULT AS ADDRESS1, 
                RTRIM(CITY) COLLATE DATABASE_DEFAULT AS CITY, 
                RTRIM(STATE) COLLATE DATABASE_DEFAULT AS STATE, 
                RTRIM(ZIPCODE) COLLATE DATABASE_DEFAULT AS ZIPCODE
            FROM ' + QUOTENAME(@TargetDB) + N'.dbo.SY01500
        ) AS Source
        ON (Target.CMPANYID = Source.CMPANYID)
        WHEN MATCHED THEN
            UPDATE SET 
                Target.CMPNYNAM = Source.CMPNYNAM,
                Target.ADDRESS1 = Source.ADDRESS1,
                Target.CITY = Source.CITY,
                Target.STATE = Source.STATE,
                Target.ZIPCODE = Source.ZIPCODE
        WHEN NOT MATCHED THEN
            INSERT (CMPANYID, CMPNYNAM, ADDRESS1, CITY, STATE, ZIPCODE)
            VALUES (Source.CMPANYID, Source.CMPNYNAM, Source.ADDRESS1, Source.CITY, Source.STATE, Source.ZIPCODE);
    END
    ELSE IF NOT EXISTS (SELECT 1 FROM dim.Dim_Empresa WHERE CMPANYID = 1)
    BEGIN
        INSERT INTO dim.Dim_Empresa (CMPANYID, CMPNYNAM) VALUES (1, ''' + @OrigenDB + N''');
    END;';
    
    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 4. Carga Dimensión Usuario (Origen: DYNAMICS.dbo.SY01400 o PB000500 o fallback)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Usuario', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Usuario;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Usuario
    @OrigenDB VARCHAR(50) = 'PB',
    @SystemDB VARCHAR(50) = 'DYNAMICS'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX) = N'
    IF OBJECT_ID(''' + QUOTENAME(@SystemDB) + N'.dbo.SY01400'') IS NOT NULL
    BEGIN
        MERGE INTO dim.Dim_Usuario AS Target
        USING (
            SELECT DISTINCT
                RTRIM(USERID) COLLATE DATABASE_DEFAULT AS USERID, 
                RTRIM(USERNAME) COLLATE DATABASE_DEFAULT AS USERNAME, 
                ''SISTEMA'' AS USERCLASS
            FROM ' + QUOTENAME(@SystemDB) + N'.dbo.SY01400
        ) AS Source
        ON (Target.USERID = Source.USERID)
        WHEN MATCHED THEN
            UPDATE SET 
                Target.USERNAME = Source.USERNAME
        WHEN NOT MATCHED THEN
            INSERT (USERID, USERNAME, USERCLASS, ROL)
            VALUES (Source.USERID, Source.USERNAME, Source.USERCLASS, ''USUARIO DE SISTEMA'');
    END;

    IF OBJECT_ID(''' + QUOTENAME(@OrigenDB) + N'.dbo.PB000500'') IS NOT NULL
    BEGIN
        MERGE INTO dim.Dim_Usuario AS Target
        USING (
            SELECT DISTINCT RTRIM(USERID) COLLATE DATABASE_DEFAULT AS USERID
            FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.PB000500
            WHERE RTRIM(USERID) <> ''''
        ) AS Source
        ON (Target.USERID = Source.USERID)
        WHEN NOT MATCHED THEN
            INSERT (USERID, USERNAME, USERCLASS, ROL)
            VALUES (Source.USERID, Source.USERID, ''REPARTIDOR'', ''REPARTIDOR/GESTOR'');
    END;

    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Usuario WHERE USERID = ''SA'')
    BEGIN
        INSERT INTO dim.Dim_Usuario (USERID, USERNAME, USERCLASS, ROL) VALUES (''SA'', ''SYSTEM ADMIN'', ''ADMIN'', ''ADMINISTRADOR'');
    END;';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 5. Carga Dimensión Cliente (Origen: RM00101 - MERGE SCD Type 1)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Cliente', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Cliente;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Cliente
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    WITH SourceRaw AS (
        SELECT 
            RTRIM(CUSTNMBR) COLLATE DATABASE_DEFAULT AS CUSTNMBR, 
            RTRIM(CUSTNAME) COLLATE DATABASE_DEFAULT AS CUSTNAME, 
            RTRIM(CUSTCLAS) COLLATE DATABASE_DEFAULT AS CUSTCLAS, 
            RTRIM(CPRCSTNM) COLLATE DATABASE_DEFAULT AS CPRCSTNM, 
            '''' AS SALSTERR, 
            RTRIM(SLPRSNID) COLLATE DATABASE_DEFAULT AS SLPRSNID, 
            RTRIM(UPSZONE) COLLATE DATABASE_DEFAULT AS UPSZONE, 
            RTRIM(PYMTRMID) COLLATE DATABASE_DEFAULT AS PYMTRMID, 
            RTRIM(SHIPMTHD) COLLATE DATABASE_DEFAULT AS SHIPMTHD, 
            RTRIM(TAXSCHID) COLLATE DATABASE_DEFAULT AS TAXSCHID,
            ROW_NUMBER() OVER (PARTITION BY RTRIM(CUSTNMBR) COLLATE DATABASE_DEFAULT ORDER BY DEX_ROW_ID DESC) AS RowNum
        FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.RM00101
    )
    MERGE INTO dim.Dim_Cliente AS Target
    USING (SELECT * FROM SourceRaw WHERE RowNum = 1) AS Source
    ON (Target.CUSTNMBR = Source.CUSTNMBR)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.CUSTNAME = Source.CUSTNAME,
            Target.CUSTCLAS = Source.CUSTCLAS,
            Target.CPRCSTNM = Source.CPRCSTNM,
            Target.SALSTERR = Source.SALSTERR,
            Target.SLPRSNID = Source.SLPRSNID,
            Target.UPSZONE = Source.UPSZONE,
            Target.PYMTRMID = Source.PYMTRMID,
            Target.SHIPMTHD = Source.SHIPMTHD,
            Target.TAXSCHID = Source.TAXSCHID
    WHEN NOT MATCHED THEN
        INSERT (CUSTNMBR, CUSTNAME, CUSTCLAS, CPRCSTNM, SALSTERR, SLPRSNID, UPSZONE, PYMTRMID, SHIPMTHD, TAXSCHID, Fecha_Inicio_SCD, Es_Actual)
        VALUES (Source.CUSTNMBR, Source.CUSTNAME, Source.CUSTCLAS, Source.CPRCSTNM, Source.SALSTERR, Source.SLPRSNID, Source.UPSZONE, Source.PYMTRMID, Source.SHIPMTHD, Source.TAXSCHID, GETDATE(), 1);';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 6. Carga Dimensión Proveedor (Origen: PM00200)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Proveedor', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Proveedor;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Proveedor
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    WITH SourceRaw AS (
        SELECT 
            RTRIM(VENDORID) COLLATE DATABASE_DEFAULT AS VENDORID, 
            RTRIM(VENDNAME) COLLATE DATABASE_DEFAULT AS VENDNAME, 
            RTRIM(VNDCLSID) COLLATE DATABASE_DEFAULT AS VNDCLTRM, 
            RTRIM(VENDSHNM) COLLATE DATABASE_DEFAULT AS VENDSHNM, 
            RTRIM(PYMTRMID) COLLATE DATABASE_DEFAULT AS PYMTRMID, 
            RTRIM(SHIPMTHD) COLLATE DATABASE_DEFAULT AS SHIPMTHD, 
            RTRIM(TAXSCHID) COLLATE DATABASE_DEFAULT AS TAXSCHID, 
            RTRIM(CURNCYID) COLLATE DATABASE_DEFAULT AS CURNCYID,
            ROW_NUMBER() OVER (PARTITION BY RTRIM(VENDORID) COLLATE DATABASE_DEFAULT ORDER BY DEX_ROW_ID DESC) AS RowNum
        FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.PM00200
    )
    MERGE INTO dim.Dim_Proveedor AS Target
    USING (SELECT * FROM SourceRaw WHERE RowNum = 1) AS Source
    ON (Target.VENDORID = Source.VENDORID)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.VENDNAME = Source.VENDNAME,
            Target.VNDCLTRM = Source.VNDCLTRM,
            Target.VENDSHNM = Source.VENDSHNM,
            Target.PYMTRMID = Source.PYMTRMID,
            Target.SHIPMTHD = Source.SHIPMTHD,
            Target.TAXSCHID = Source.TAXSCHID,
            Target.CURNCYID = Source.CURNCYID
    WHEN NOT MATCHED THEN
        INSERT (VENDORID, VENDNAME, VNDCLTRM, VENDSHNM, PYMTRMID, SHIPMTHD, TAXSCHID, CURNCYID)
        VALUES (Source.VENDORID, Source.VENDNAME, Source.VNDCLTRM, Source.VENDSHNM, Source.PYMTRMID, Source.SHIPMTHD, Source.TAXSCHID, Source.CURNCYID);';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 7. Carga Dimensión Producto (Origen: IV00101)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Producto', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Producto;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Producto
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    WITH SourceRaw AS (
        SELECT 
            RTRIM(ITEMNMBR) COLLATE DATABASE_DEFAULT AS ITEMNMBR, 
            RTRIM(ITEMDESC) COLLATE DATABASE_DEFAULT AS ITEMDESC, 
            RTRIM(ITMCLSCD) COLLATE DATABASE_DEFAULT AS ITMCLSCD, 
            RTRIM(UOMSCHDL) COLLATE DATABASE_DEFAULT AS UOMSCHDL, 
            ITEMTYPE, DECPLQTY, DECPLCUR, STNDCOST, CURRCOST,
            ROW_NUMBER() OVER (PARTITION BY RTRIM(ITEMNMBR) COLLATE DATABASE_DEFAULT ORDER BY DEX_ROW_ID DESC) AS RowNum
        FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.IV00101
    )
    MERGE INTO dim.Dim_Producto AS Target
    USING (SELECT * FROM SourceRaw WHERE RowNum = 1) AS Source
    ON (Target.ITEMNMBR = Source.ITEMNMBR)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ITEMDESC = Source.ITEMDESC,
            Target.ITMCLSCD = Source.ITMCLSCD,
            Target.UOMSCHDL = Source.UOMSCHDL,
            Target.ITEMTYPE = Source.ITEMTYPE,
            Target.DECPLQTY = Source.DECPLQTY,
            Target.DECPLCUR = Source.DECPLCUR,
            Target.STNDCOST = Source.STNDCOST,
            Target.CURRCOST = Source.CURRCOST
    WHEN NOT MATCHED THEN
        INSERT (ITEMNMBR, ITEMDESC, ITMCLSCD, UOMSCHDL, ITEMTYPE, DECPLQTY, DECPLCUR, STNDCOST, CURRCOST)
        VALUES (Source.ITEMNMBR, Source.ITEMDESC, Source.ITMCLSCD, Source.UOMSCHDL, Source.ITEMTYPE, Source.DECPLQTY, Source.DECPLCUR, Source.STNDCOST, Source.CURRCOST);';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 8. Carga Dimensión Cuenta Contable (Origen: GL00100 / GL00105)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Cuenta_Contable', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Cuenta_Contable;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Cuenta_Contable
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    WITH SourceRaw AS (
        SELECT 
            A.ACTINDX, 
            RTRIM(ISNULL(I.ACTNUMST, CAST(A.ACTINDX AS VARCHAR(20)))) COLLATE DATABASE_DEFAULT AS ACTNUMST, 
            RTRIM(A.ACTDESCR) COLLATE DATABASE_DEFAULT AS ACTDESCR, 
            A.ACCTTYPE, A.ACCATNUM,
            ROW_NUMBER() OVER (PARTITION BY A.ACTINDX ORDER BY A.DEX_ROW_ID DESC) AS RowNum
        FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.GL00100 A
        LEFT JOIN ' + QUOTENAME(@OrigenDB) + N'.dbo.GL00105 I ON A.ACTINDX = I.ACTINDX
    )
    MERGE INTO dim.Dim_Cuenta_Contable AS Target
    USING (SELECT * FROM SourceRaw WHERE RowNum = 1) AS Source
    ON (Target.ACTINDX = Source.ACTINDX)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.ACTNUMST = Source.ACTNUMST,
            Target.ACTDESCR = Source.ACTDESCR,
            Target.ACCTTYPE = Source.ACCTTYPE,
            Target.ACCATNUM = Source.ACCATNUM
    WHEN NOT MATCHED THEN
        INSERT (ACTINDX, ACTNUMST, ACTDESCR, ACCTTYPE, ACCATNUM)
        VALUES (Source.ACTINDX, Source.ACTNUMST, Source.ACTDESCR, Source.ACCTTYPE, Source.ACCATNUM);';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 9. Carga Dimensión Almacén (Origen: IV00102 / LOCNCODE)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Almacen', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Almacen;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Almacen
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    MERGE INTO dim.Dim_Almacen AS Target
    USING (
        SELECT DISTINCT RTRIM(LOCNCODE) COLLATE DATABASE_DEFAULT AS LOCNCODE
        FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.IV00102
        WHERE RTRIM(LOCNCODE) <> ''''
    ) AS Source
    ON (Target.LOCNCODE = Source.LOCNCODE)
    WHEN NOT MATCHED THEN
        INSERT (LOCNCODE, LOCNDSCR)
        VALUES (Source.LOCNCODE, ''ALMACEN '' + Source.LOCNCODE);';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 10. Carga Dimensión Método de Envío (Extracción Dinámica Multitabla)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Dim_Metodo_Envio', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Dim_Metodo_Envio;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Dim_Metodo_Envio
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX) = N'
    WITH Metodos AS (
        SELECT DISTINCT RTRIM(SHIPMTHD) COLLATE DATABASE_DEFAULT AS SHIPMTHD FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.SOP30200 WHERE RTRIM(SHIPMTHD) <> ''''
        UNION
        SELECT DISTINCT RTRIM(SHIPMTHD) COLLATE DATABASE_DEFAULT AS SHIPMTHD FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.RM00101 WHERE RTRIM(SHIPMTHD) <> ''''
        UNION
        SELECT DISTINCT RTRIM(SHIPMTHD) COLLATE DATABASE_DEFAULT AS SHIPMTHD FROM ' + QUOTENAME(@OrigenDB) + N'.dbo.PM00200 WHERE RTRIM(SHIPMTHD) <> ''''
    )
    MERGE INTO dim.Dim_Metodo_Envio AS Target
    USING Metodos AS Source
    ON (Target.SHIPMTHD = Source.SHIPMTHD)
    WHEN NOT MATCHED THEN
        INSERT (SHIPMTHD, CARRIER, SHIPTYPE)
        VALUES (Source.SHIPMTHD, Source.SHIPMTHD, 1);

    IF NOT EXISTS (SELECT 1 FROM dim.Dim_Metodo_Envio WHERE SHIPMTHD = ''DEFAULT'')
    BEGIN
        INSERT INTO dim.Dim_Metodo_Envio (SHIPMTHD, CARRIER, SHIPTYPE) VALUES (''DEFAULT'', ''STANDARD'', 1);
    END;';

    EXEC sp_executesql @SQL;
END;
GO

-- -------------------------------------------------------------------------------
-- 11. Procedimiento Maestro: Cargar Todas las Dimensiones
-- -------------------------------------------------------------------------------
IF OBJECT_ID('dim.sp_ETL_Cargar_Todas_Dimensiones', 'P') IS NOT NULL DROP PROCEDURE dim.sp_ETL_Cargar_Todas_Dimensiones;
GO
CREATE PROCEDURE dim.sp_ETL_Cargar_Todas_Dimensiones
    @OrigenDB VARCHAR(50) = 'PB',
    @SystemDB VARCHAR(50) = 'DYNAMICS'
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dim.sp_ETL_Cargar_Dim_Tiempo @OrigenDB = @OrigenDB, @Anio_Inicio = 2000, @Anio_Fin = 2035;
    EXEC dim.sp_ETL_Cargar_Dim_Tasa_Cambio @OrigenDB = @OrigenDB, @SystemDB = @SystemDB;
    EXEC dim.sp_ETL_Cargar_Dim_Empresa @OrigenDB = @OrigenDB, @SystemDB = @SystemDB;
    EXEC dim.sp_ETL_Cargar_Dim_Usuario @OrigenDB = @OrigenDB, @SystemDB = @SystemDB;
    EXEC dim.sp_ETL_Cargar_Dim_Cliente @OrigenDB = @OrigenDB;
    EXEC dim.sp_ETL_Cargar_Dim_Proveedor @OrigenDB = @OrigenDB;
    EXEC dim.sp_ETL_Cargar_Dim_Producto @OrigenDB = @OrigenDB;
    EXEC dim.sp_ETL_Cargar_Dim_Cuenta_Contable @OrigenDB = @OrigenDB;
    EXEC dim.sp_ETL_Cargar_Dim_Almacen @OrigenDB = @OrigenDB;
    EXEC dim.sp_ETL_Cargar_Dim_Metodo_Envio @OrigenDB = @OrigenDB;
END;
GO
