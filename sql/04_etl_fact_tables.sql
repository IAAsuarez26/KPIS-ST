-- ===============================================================================
-- ETL TABLAS DE HECHOS (4 DATA MARTS DE PRODUCCIÓN - UPSERT/MERGE INCREMENTAL VEF/USD): DW_PB
-- Motor: Microsoft SQL Server (T-SQL)
-- Origen de Datos: Microsoft Dynamics GP (script-PB.sql / Base de Datos Origen [PB])
-- Collation Safety: COLLATE DATABASE_DEFAULT en todas las comparaciones de texto
-- ===============================================================================

USE [DW_PB];
GO

-- -------------------------------------------------------------------------------
-- 1. Carga Fact Ventas Transaccional (Tasa_Ventas de USD-VENTAS)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_ventas.sp_ETL_Cargar_Fact_Ventas', 'P') IS NOT NULL DROP PROCEDURE fact_ventas.sp_ETL_Cargar_Fact_Ventas;
GO
CREATE PROCEDURE fact_ventas.sp_ETL_Cargar_Fact_Ventas
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;

    -- 1.1 Limpieza preventiva de posibles filas duplicadas existentes en Target
    WITH TargetDuplicates AS (
        SELECT 
            Venta_ID,
            ROW_NUMBER() OVER (
                PARTITION BY SOPTYPE, SOPNUMBE, LNITMSEQ 
                ORDER BY Venta_ID ASC
            ) AS RowNum
        FROM fact_ventas.Fact_Ventas_Transaccional
    )
    DELETE FROM TargetDuplicates WHERE RowNum > 1;

    -- 1.2 MERGE con deduplicación estricta en Source
    WITH SourceRaw AS (
        SELECT 
            H.SOPTYPE, 
            RTRIM(H.SOPNUMBE) COLLATE DATABASE_DEFAULT AS SOPNUMBE, 
            RTRIM(H.DOCID) COLLATE DATABASE_DEFAULT AS DOCID,
            L.LNITMSEQ,
            ISNULL(T.Tiempo_SK, 19000101) AS Tiempo_SK,
            ISNULL(C.Cliente_SK, 1) AS Cliente_SK,
            ISNULL(P.Producto_SK, 1) AS Producto_SK,
            ISNULL(E.Empresa_SK, 1) AS Empresa_SK,
            ISNULL(A.Almacen_SK, 1) AS Almacen_SK,
            ISNULL(U.Usuario_SK, 1) AS Usuario_SK,
            L.QUANTITY AS Cantidad,
            L.UNITPRCE AS Precio_Unitario_VEF,
            L.UNITCOST AS Costo_Unitario_VEF,
            L.XTNDPRCE AS Monto_Bruto_VEF,
            L.MRKDNAMT AS Monto_Descuento_VEF,
            L.TAXAMNT AS Monto_Impuesto_VEF,
            (L.XTNDPRCE - L.MRKDNAMT + L.TAXAMNT) AS Monto_Neto_VEF,
            (L.QUANTITY * L.UNITCOST) AS Costo_Total_VEF,
            ((L.XTNDPRCE - L.MRKDNAMT) - (L.QUANTITY * L.UNITCOST)) AS Margen_Ganancia_VEF,
            ISNULL(TC.Tasa_Ventas, 1.0) AS Tasa_Cambio_Ventas,
            CASE WHEN ISNULL(TC.Tasa_Ventas, 0) > 0 THEN (L.XTNDPRCE - L.MRKDNAMT + L.TAXAMNT) / TC.Tasa_Ventas ELSE (L.XTNDPRCE - L.MRKDNAMT + L.TAXAMNT) END AS Monto_Neto_USD,
            CASE WHEN ISNULL(TC.Tasa_Ventas, 0) > 0 THEN (L.QUANTITY * L.UNITCOST) / TC.Tasa_Ventas ELSE (L.QUANTITY * L.UNITCOST) END AS Costo_Total_USD,
            CASE WHEN ISNULL(TC.Tasa_Ventas, 0) > 0 THEN ((L.XTNDPRCE - L.MRKDNAMT) - (L.QUANTITY * L.UNITCOST)) / TC.Tasa_Ventas ELSE ((L.XTNDPRCE - L.MRKDNAMT) - (L.QUANTITY * L.UNITCOST)) END AS Margen_Ganancia_USD,
            ROW_NUMBER() OVER (
                PARTITION BY H.SOPTYPE, RTRIM(H.SOPNUMBE) COLLATE DATABASE_DEFAULT, L.LNITMSEQ 
                ORDER BY H.DEX_ROW_ID DESC, L.DEX_ROW_ID DESC
            ) AS RowNum
        FROM PB.dbo.SOP30200 H
        INNER JOIN PB.dbo.SOP30300 L ON H.SOPTYPE = L.SOPTYPE AND H.SOPNUMBE = L.SOPNUMBE
        LEFT JOIN dim.Dim_Tiempo T ON T.Fecha = CAST(H.DOCDATE AS DATE)
        LEFT JOIN dim.Dim_Tasa_Cambio TC ON TC.Fecha = CAST(H.DOCDATE AS DATE)
        LEFT JOIN dim.Dim_Cliente C ON C.CUSTNMBR = RTRIM(H.CUSTNMBR) COLLATE DATABASE_DEFAULT AND C.Es_Actual = 1
        LEFT JOIN dim.Dim_Producto P ON P.ITEMNMBR = RTRIM(L.ITEMNMBR) COLLATE DATABASE_DEFAULT
        LEFT JOIN dim.Dim_Empresa E ON E.CMPANYID = 1
        LEFT JOIN dim.Dim_Almacen A ON A.LOCNCODE = RTRIM(L.LOCNCODE) COLLATE DATABASE_DEFAULT
        LEFT JOIN dim.Dim_Usuario U ON U.USERID = RTRIM(H.USER2ENT) COLLATE DATABASE_DEFAULT
    )
    MERGE INTO fact_ventas.Fact_Ventas_Transaccional AS Target
    USING (
        SELECT * FROM SourceRaw WHERE RowNum = 1
    ) AS Source
    ON (Target.SOPTYPE = Source.SOPTYPE AND Target.SOPNUMBE = Source.SOPNUMBE AND Target.LNITMSEQ = Source.LNITMSEQ)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.DOCID = Source.DOCID,
            Target.Cantidad = Source.Cantidad,
            Target.Precio_Unitario_VEF = Source.Precio_Unitario_VEF,
            Target.Costo_Unitario_VEF = Source.Costo_Unitario_VEF,
            Target.Monto_Bruto_VEF = Source.Monto_Bruto_VEF,
            Target.Monto_Descuento_VEF = Source.Monto_Descuento_VEF,
            Target.Monto_Impuesto_VEF = Source.Monto_Impuesto_VEF,
            Target.Monto_Neto_VEF = Source.Monto_Neto_VEF,
            Target.Costo_Total_VEF = Source.Costo_Total_VEF,
            Target.Margen_Ganancia_VEF = Source.Margen_Ganancia_VEF,
            Target.Tasa_Cambio_Ventas = Source.Tasa_Cambio_Ventas,
            Target.Monto_Neto_USD = Source.Monto_Neto_USD,
            Target.Costo_Total_USD = Source.Costo_Total_USD,
            Target.Margen_Ganancia_USD = Source.Margen_Ganancia_USD
    WHEN NOT MATCHED THEN
        INSERT (
            SOPTYPE, SOPNUMBE, DOCID, LNITMSEQ, Tiempo_SK, Cliente_SK, Producto_SK, Empresa_SK, Almacen_SK, Usuario_SK,
            Cantidad, Precio_Unitario_VEF, Costo_Unitario_VEF, Monto_Bruto_VEF, Monto_Descuento_VEF, Monto_Impuesto_VEF, Monto_Neto_VEF, Costo_Total_VEF, Margen_Ganancia_VEF,
            Tasa_Cambio_Ventas, Monto_Neto_USD, Costo_Total_USD, Margen_Ganancia_USD
        )
        VALUES (
            Source.SOPTYPE, Source.SOPNUMBE, Source.DOCID, Source.LNITMSEQ, Source.Tiempo_SK, Source.Cliente_SK, Source.Producto_SK, Source.Empresa_SK, Source.Almacen_SK, Source.Usuario_SK,
            Source.Cantidad, Source.Precio_Unitario_VEF, Source.Costo_Unitario_VEF, Source.Monto_Bruto_VEF, Source.Monto_Descuento_VEF, Source.Monto_Impuesto_VEF, Source.Monto_Neto_VEF, Source.Costo_Total_VEF, Source.Margen_Ganancia_VEF,
            Source.Tasa_Cambio_Ventas, Source.Monto_Neto_USD, Source.Costo_Total_USD, Source.Margen_Ganancia_USD
        );
END;
GO

-- -------------------------------------------------------------------------------
-- 2. Carga Fact Compras Ordenes (Tasa_Compras de USD-COMPRAS)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_compras.sp_ETL_Cargar_Fact_Compras', 'P') IS NOT NULL DROP PROCEDURE fact_compras.sp_ETL_Cargar_Fact_Compras;
GO
CREATE PROCEDURE fact_compras.sp_ETL_Cargar_Fact_Compras
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;

    -- 2.1 Limpieza preventiva de posibles filas duplicadas existentes en Target
    WITH TargetDuplicates AS (
        SELECT 
            Compra_ID,
            ROW_NUMBER() OVER (
                PARTITION BY PONUMBER, ORD 
                ORDER BY Compra_ID ASC
            ) AS RowNum
        FROM fact_compras.Fact_Compras_Ordenes
    )
    DELETE FROM TargetDuplicates WHERE RowNum > 1;

    -- 2.2 MERGE con deduplicación estricta en Source
    WITH SourceRaw AS (
        SELECT 
            RTRIM(H.PONUMBER) COLLATE DATABASE_DEFAULT AS PONUMBER, 
            L.ORD,
            ISNULL(T1.Tiempo_SK, 19000101) AS Tiempo_Orden_SK,
            ISNULL(T2.Tiempo_SK, 19000101) AS Tiempo_Requerido_SK,
            ISNULL(V.Proveedor_SK, 1) AS Proveedor_SK,
            ISNULL(P.Producto_SK, 1) AS Producto_SK,
            ISNULL(E.Empresa_SK, 1) AS Empresa_SK,
            ISNULL(A.Almacen_SK, 1) AS Almacen_SK,
            L.QTYORDER AS Cantidad_Ordenada,
            L.QTYCANCE AS Cantidad_Cancelada,
            (L.QTYORDER - L.QTYCANCE) AS Cantidad_Recibida,
            L.UNITCOST AS Costo_Unitario_VEF,
            L.EXTDCOST AS Monto_Total_Orden_VEF,
            ISNULL(TC.Tasa_Compras, 1.0) AS Tasa_Cambio_Compras,
            CASE WHEN ISNULL(TC.Tasa_Compras, 0) > 0 THEN L.EXTDCOST / TC.Tasa_Compras ELSE L.EXTDCOST END AS Monto_Total_Orden_USD,
            ROW_NUMBER() OVER (
                PARTITION BY RTRIM(H.PONUMBER) COLLATE DATABASE_DEFAULT, L.ORD 
                ORDER BY H.DEX_ROW_ID DESC, L.DEX_ROW_ID DESC
            ) AS RowNum
        FROM PB.dbo.POP30100 H
        INNER JOIN PB.dbo.POP30110 L ON H.PONUMBER = L.PONUMBER
        LEFT JOIN dim.Dim_Tiempo T1 ON T1.Fecha = CAST(H.DOCDATE AS DATE)
        LEFT JOIN dim.Dim_Tiempo T2 ON T2.Fecha = CAST(L.PRMDATE AS DATE)
        LEFT JOIN dim.Dim_Tasa_Cambio TC ON TC.Fecha = CAST(H.DOCDATE AS DATE)
        LEFT JOIN dim.Dim_Proveedor V ON V.VENDORID = RTRIM(H.VENDORID) COLLATE DATABASE_DEFAULT
        LEFT JOIN dim.Dim_Producto P ON P.ITEMNMBR = RTRIM(L.ITEMNMBR) COLLATE DATABASE_DEFAULT
        LEFT JOIN dim.Dim_Empresa E ON E.CMPANYID = H.CMPANYID
        LEFT JOIN dim.Dim_Almacen A ON A.LOCNCODE = RTRIM(L.LOCNCODE) COLLATE DATABASE_DEFAULT
    )
    MERGE INTO fact_compras.Fact_Compras_Ordenes AS Target
    USING (
        SELECT * FROM SourceRaw WHERE RowNum = 1
    ) AS Source
    ON (Target.PONUMBER = Source.PONUMBER AND Target.ORD = Source.ORD)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Cantidad_Ordenada = Source.Cantidad_Ordenada,
            Target.Cantidad_Recibida = Source.Cantidad_Recibida,
            Target.Cantidad_Cancelada = Source.Cantidad_Cancelada,
            Target.Costo_Unitario_VEF = Source.Costo_Unitario_VEF,
            Target.Monto_Total_Orden_VEF = Source.Monto_Total_Orden_VEF,
            Target.Tasa_Cambio_Compras = Source.Tasa_Cambio_Compras,
            Target.Monto_Total_Orden_USD = Source.Monto_Total_Orden_USD
    WHEN NOT MATCHED THEN
        INSERT (
            PONUMBER, ORD, Tiempo_Orden_SK, Tiempo_Requerido_SK, Proveedor_SK, Producto_SK, Empresa_SK, Almacen_SK,
            Cantidad_Ordenada, Cantidad_Recibida, Cantidad_Cancelada, Costo_Unitario_VEF, Monto_Total_Orden_VEF, Tasa_Cambio_Compras, Monto_Total_Orden_USD
        )
        VALUES (
            Source.PONUMBER, Source.ORD, Source.Tiempo_Orden_SK, Source.Tiempo_Requerido_SK, Source.Proveedor_SK, Source.Producto_SK, Source.Empresa_SK, Source.Almacen_SK,
            Source.Cantidad_Ordenada, Source.Cantidad_Recibida, Source.Cantidad_Cancelada, Source.Costo_Unitario_VEF, Source.Monto_Total_Orden_VEF, Source.Tasa_Cambio_Compras, Source.Monto_Total_Orden_USD
        );
END;
GO

-- -------------------------------------------------------------------------------
-- 3. Carga Fact Movimientos Contables (Tasa_Financiero de USD-FINANCIERO)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_finanzas.sp_ETL_Cargar_Fact_Finanzas', 'P') IS NOT NULL DROP PROCEDURE fact_finanzas.sp_ETL_Cargar_Fact_Finanzas;
GO
CREATE PROCEDURE fact_finanzas.sp_ETL_Cargar_Fact_Finanzas
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;

    -- 3.1 Limpieza preventiva de posibles filas duplicadas existentes en Target
    WITH TargetDuplicates AS (
        SELECT 
            MovimientoContable_ID,
            ROW_NUMBER() OVER (
                PARTITION BY JRNENTRY, SQNCLINE 
                ORDER BY MovimientoContable_ID ASC
            ) AS RowNum
        FROM fact_finanzas.Fact_Movimientos_Contables
    )
    DELETE FROM TargetDuplicates WHERE RowNum > 1;

    -- 3.2 MERGE con deduplicación estricta en Source
    WITH SourceRaw AS (
        SELECT 
            G.JRNENTRY, 
            G.SEQNUMBR AS SQNCLINE,
            ISNULL(T.Tiempo_SK, 19000101) AS Tiempo_SK,
            ISNULL(C.Cuenta_SK, 1) AS Cuenta_SK,
            1 AS CentroCosto_SK,
            ISNULL(E.Empresa_SK, 1) AS Empresa_SK,
            G.DEBITAMT AS Monto_Debito_VEF,
            G.CRDTAMNT AS Monto_Credito_VEF,
            (G.DEBITAMT - G.CRDTAMNT) AS Monto_Neto_VEF,
            ISNULL(TC.Tasa_Financiero, 1.0) AS Tasa_Cambio_Financiero,
            CASE WHEN ISNULL(TC.Tasa_Financiero, 0) > 0 THEN G.DEBITAMT / TC.Tasa_Financiero ELSE G.DEBITAMT END AS Monto_Debito_USD,
            CASE WHEN ISNULL(TC.Tasa_Financiero, 0) > 0 THEN G.CRDTAMNT / TC.Tasa_Financiero ELSE G.CRDTAMNT END AS Monto_Credito_USD,
            CASE WHEN ISNULL(TC.Tasa_Financiero, 0) > 0 THEN (G.DEBITAMT - G.CRDTAMNT) / TC.Tasa_Financiero ELSE (G.DEBITAMT - G.CRDTAMNT) END AS Monto_Neto_USD,
            RTRIM(G.CURNCYID) COLLATE DATABASE_DEFAULT AS CURNCYID,
            ROW_NUMBER() OVER (
                PARTITION BY G.JRNENTRY, G.SEQNUMBR 
                ORDER BY G.DEX_ROW_ID DESC
            ) AS RowNum
        FROM PB.dbo.GL30000 G
        LEFT JOIN dim.Dim_Tiempo T ON T.Fecha = CAST(G.TRXDATE AS DATE)
        LEFT JOIN dim.Dim_Tasa_Cambio TC ON TC.Fecha = CAST(G.TRXDATE AS DATE)
        LEFT JOIN dim.Dim_Cuenta_Contable C ON C.ACTINDX = G.ACTINDX
        LEFT JOIN dim.Dim_Empresa E ON E.CMPANYID = 1
    )
    MERGE INTO fact_finanzas.Fact_Movimientos_Contables AS Target
    USING (
        SELECT * FROM SourceRaw WHERE RowNum = 1
    ) AS Source
    ON (Target.JRNENTRY = Source.JRNENTRY AND Target.SQNCLINE = Source.SQNCLINE)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Monto_Debito_VEF = Source.Monto_Debito_VEF,
            Target.Monto_Credito_VEF = Source.Monto_Credito_VEF,
            Target.Monto_Neto_VEF = Source.Monto_Neto_VEF,
            Target.Tasa_Cambio_Financiero = Source.Tasa_Cambio_Financiero,
            Target.Monto_Debito_USD = Source.Monto_Debito_USD,
            Target.Monto_Credito_USD = Source.Monto_Credito_USD,
            Target.Monto_Neto_USD = Source.Monto_Neto_USD
    WHEN NOT MATCHED THEN
        INSERT (
            JRNENTRY, SQNCLINE, Tiempo_SK, Cuenta_SK, CentroCosto_SK, Empresa_SK,
            Monto_Debito_VEF, Monto_Credito_VEF, Monto_Neto_VEF, Tasa_Cambio_Financiero, Monto_Debito_USD, Monto_Credito_USD, Monto_Neto_USD, CURNCYID
        )
        VALUES (
            Source.JRNENTRY, Source.SQNCLINE, Source.Tiempo_SK, Source.Cuenta_SK, Source.CentroCosto_SK, Source.Empresa_SK,
            Source.Monto_Debito_VEF, Source.Monto_Credito_VEF, Source.Monto_Neto_VEF, Source.Tasa_Cambio_Financiero, Source.Monto_Debito_USD, Source.Monto_Credito_USD, Source.Monto_Neto_USD, Source.CURNCYID
        );
END;
GO

-- -------------------------------------------------------------------------------
-- 4. Carga Fact Entrega Facturas Cliente (PB000500 - Tasa_Ventas de USD-VENTAS)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_logistica.sp_ETL_Cargar_Fact_Entrega_Facturas_Cliente', 'P') IS NOT NULL DROP PROCEDURE fact_logistica.sp_ETL_Cargar_Fact_Entrega_Facturas_Cliente;
GO
CREATE PROCEDURE fact_logistica.sp_ETL_Cargar_Fact_Entrega_Facturas_Cliente
    @OrigenDB VARCHAR(50) = 'PB'
AS
BEGIN
    SET NOCOUNT ON;

    -- 4.1 Limpieza preventiva de posibles filas duplicadas existentes en Target
    WITH TargetDuplicates AS (
        SELECT 
            EntregaFactura_ID,
            ROW_NUMBER() OVER (
                PARTITION BY SOPTYPE, SOPNUMBE 
                ORDER BY EntregaFactura_ID ASC
            ) AS RowNum
        FROM fact_logistica.Fact_Entrega_Facturas_Cliente
    )
    DELETE FROM TargetDuplicates WHERE RowNum > 1;

    -- 4.2 MERGE con deduplicación estricta en Source
    WITH SourceRaw AS (
        SELECT 
            PB.SOPTYPE, 
            RTRIM(PB.SOPNUMBE) COLLATE DATABASE_DEFAULT AS SOPNUMBE,
            ISNULL(C.Cliente_SK, 1) AS Cliente_SK,
            ISNULL(U.Usuario_SK, 1) AS Usuario_Repartidor_SK,
            ISNULL(T_Emision.Tiempo_SK, 19000101) AS Tiempo_Emision_SK,
            ISNULL(T_Entrega.Tiempo_SK, 19000101) AS Tiempo_Entrega_SK,
            ISNULL(T_VencOrig.Tiempo_SK, 19000101) AS Tiempo_Vencimiento_Original_SK,
            ISNULL(T_VencNuev.Tiempo_SK, 19000101) AS Tiempo_Nuevo_Vencimiento_SK,
            1 AS Empresa_SK,
            DATEDIFF(DAY, PB.DOCDATE, PB.DATE1) AS Dias_Para_Entrega_Factura,
            DATEDIFF(DAY, PB.DUEDATE, PB.DocDueDate) AS Dias_Desplazamiento_Vencimiento,
            CASE WHEN PB.DATE1 > PB.DUEDATE THEN 1 ELSE 0 END AS Es_Entrega_Con_Retraso,
            ISNULL(TC.Tasa_Ventas, 1.0) AS Tasa_Cambio_Ventas,
            ROW_NUMBER() OVER (
                PARTITION BY PB.SOPTYPE, RTRIM(PB.SOPNUMBE) COLLATE DATABASE_DEFAULT 
                ORDER BY PB.DATE1 DESC, PB.DEX_ROW_ID DESC
            ) AS RowNum
        FROM PB.dbo.PB000500 PB
        LEFT JOIN dim.Dim_Cliente C ON C.CUSTNMBR = RTRIM(PB.CUSTNMBR) COLLATE DATABASE_DEFAULT AND C.Es_Actual = 1
        LEFT JOIN dim.Dim_Usuario U ON U.USERID = RTRIM(PB.USERID) COLLATE DATABASE_DEFAULT
        LEFT JOIN dim.Dim_Tiempo T_Emision ON T_Emision.Fecha = CAST(PB.DOCDATE AS DATE)
        LEFT JOIN dim.Dim_Tiempo T_Entrega ON T_Entrega.Fecha = CAST(PB.DATE1 AS DATE)
        LEFT JOIN dim.Dim_Tiempo T_VencOrig ON T_VencOrig.Fecha = CAST(PB.DUEDATE AS DATE)
        LEFT JOIN dim.Dim_Tiempo T_VencNuev ON T_VencNuev.Fecha = CAST(PB.DocDueDate AS DATE)
        LEFT JOIN dim.Dim_Tasa_Cambio TC ON TC.Fecha = CAST(PB.DOCDATE AS DATE)
    )
    MERGE INTO fact_logistica.Fact_Entrega_Facturas_Cliente AS Target
    USING (
        SELECT * FROM SourceRaw WHERE RowNum = 1
    ) AS Source
    ON (Target.SOPTYPE = Source.SOPTYPE AND Target.SOPNUMBE = Source.SOPNUMBE)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Cliente_SK = Source.Cliente_SK,
            Target.Usuario_Repartidor_SK = Source.Usuario_Repartidor_SK,
            Target.Tiempo_Entrega_SK = Source.Tiempo_Entrega_SK,
            Target.Tiempo_Nuevo_Vencimiento_SK = Source.Tiempo_Nuevo_Vencimiento_SK,
            Target.Dias_Para_Entrega_Factura = Source.Dias_Para_Entrega_Factura,
            Target.Dias_Desplazamiento_Vencimiento = Source.Dias_Desplazamiento_Vencimiento,
            Target.Es_Entrega_Con_Retraso = Source.Es_Entrega_Con_Retraso,
            Target.Tasa_Cambio_Ventas = Source.Tasa_Cambio_Ventas
    WHEN NOT MATCHED THEN
        INSERT (
            SOPTYPE, SOPNUMBE, Cliente_SK, Usuario_Repartidor_SK, Tiempo_Emision_SK, Tiempo_Entrega_SK,
            Tiempo_Vencimiento_Original_SK, Tiempo_Nuevo_Vencimiento_SK, Empresa_SK,
            Dias_Para_Entrega_Factura, Dias_Desplazamiento_Vencimiento, Es_Entrega_Con_Retraso, Tasa_Cambio_Ventas
        )
        VALUES (
            Source.SOPTYPE, Source.SOPNUMBE, Source.Cliente_SK, Source.Usuario_Repartidor_SK, Source.Tiempo_Emision_SK, Source.Tiempo_Entrega_SK,
            Source.Tiempo_Vencimiento_Original_SK, Source.Tiempo_Nuevo_Vencimiento_SK, Source.Empresa_SK,
            Source.Dias_Para_Entrega_Factura, Source.Dias_Desplazamiento_Vencimiento, Source.Es_Entrega_Con_Retraso, Source.Tasa_Cambio_Ventas
        );
END;
GO

GO
