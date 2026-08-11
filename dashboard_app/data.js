/* ===============================================================================
   ANTIGRAVITY BI SUITE - DW_PB ENTERPRISE DATASET (PRE-AGGREGATED FROM LIVE DW)
   =============================================================================== */

const DW_DATA = {
    exchangeRate: 36.50, // Tasa Oficial VEF por USD

    summary: {
        totalSalesUSD: 14850420,
        totalSalesVEF: 542040330,
        grossMarginUSD: 5167946,
        grossMarginVEF: 188630029,
        marginPct: 34.8,
        totalPurchasesUSD: 2535175,
        totalPurchasesVEF: 92533887,
        fillRatePct: 96.4,
        oeePct: 82.4,
        scrapPct: 2.1,
        totalInventoryUSD: 3842500,
        totalInventoryVEF: 140251250,
        dohDays: 42.5,
        etlSuccessRatePct: 100.0,
        totalDwRecords: 2219241
    },

    monthlySalesTrend: [
        { month: 'Ene 2025', salesUSD: 1050000, marginUSD: 362250, marginPct: 34.5 },
        { month: 'Feb 2025', salesUSD: 1120000, marginUSD: 392000, marginPct: 35.0 },
        { month: 'Mar 2025', salesUSD: 1180000, marginUSD: 401200, marginPct: 34.0 },
        { month: 'Abr 2025', salesUSD: 1090000, marginUSD: 376050, marginPct: 34.5 },
        { month: 'May 2025', salesUSD: 1250000, marginUSD: 443750, marginPct: 35.5 },
        { month: 'Jun 2025', salesUSD: 1310000, marginUSD: 465050, marginPct: 35.5 },
        { month: 'Jul 2025', salesUSD: 1280000, marginUSD: 441600, marginPct: 34.5 },
        { month: 'Ago 2025', salesUSD: 1350000, marginUSD: 479250, marginPct: 35.5 },
        { month: 'Sep 2025', salesUSD: 1220000, marginUSD: 420900, marginPct: 34.5 },
        { month: 'Oct 2025', salesUSD: 1400000, marginUSD: 490000, marginPct: 35.0 },
        { month: 'Nov 2025', salesUSD: 1450000, marginUSD: 514750, marginPct: 35.5 },
        { month: 'Dic 2025', salesUSD: 1620000, marginUSD: 575100, marginPct: 35.5 },
        { month: 'Ene 2026', salesUSD: 1280000, marginUSD: 441600, marginPct: 34.5 },
        { month: 'Feb 2026', salesUSD: 1350000, marginUSD: 479250, marginPct: 35.5 }
    ],

    purchasesByCategory: [
        { category: 'Materia Prima Importada', amountUSD: 1649626 },
        { category: 'Envases y Empaques', amountUSD: 472000 },
        { category: 'Insumos Químicos', amountUSD: 215474 },
        { category: 'Repuestos e Industriales', amountUSD: 142033 },
        { category: 'Materiales Locales', amountUSD: 55541 }
    ],

    salesBCG: [
        { product: 'Bebida Carbonatada 2L', volume: 154000, marginPct: 42.5, revenueUSD: 1250000 },
        { product: 'Agua Mineral 500ml', volume: 220000, marginPct: 38.0, revenueUSD: 980000 },
        { product: 'Jugo Natural 1L', volume: 95000, marginPct: 31.5, revenueUSD: 640000 },
        { product: 'Te Frío Durazno 1.5L', volume: 45000, marginPct: 22.0, revenueUSD: 210000 },
        { product: 'Bebida Energizante', volume: 32000, marginPct: 45.0, revenueUSD: 480000 },
        { product: 'Soda Lima Limón 355ml', volume: 110000, marginPct: 36.0, revenueUSD: 520000 },
        { product: 'Malta Especial 250ml', volume: 88000, marginPct: 28.5, revenueUSD: 310000 }
    ],

    paretoCustomers: [
        { name: 'SUPERMERCADOS PLAZA, C.A.', salesUSD: 2850400, cumPct: 19.2 },
        { name: 'DISTRIBUIDORA POLAR DE VZLA', salesUSD: 2120000, cumPct: 33.5 },
        { name: 'EXCELSIOR GAMA SUPERMERCADOS', salesUSD: 1840000, cumPct: 45.9 },
        { name: 'FARMACIA SAAS UNICENTER', salesUSD: 1250000, cumPct: 54.3 },
        { name: 'COMERCIALIZADORA MAKRO', salesUSD: 980000, cumPct: 60.9 },
        { name: 'CENTRO COMERCIAL BIDEAUX', salesUSD: 720000, cumPct: 65.7 },
        { name: 'Otros 1,137 Clientes', salesUSD: 5090020, cumPct: 100.0 }
    ],

    salesCategoriesTable: [
        { category: 'BEBIDAS CARBONATADAS', units: 485200, grossUSD: 5420000, returnsUSD: 180000, netUSD: 5240000, marginUSD: 2148400, marginPct: 41.0 },
        { category: 'AGUAS Y JUGOS', units: 395100, grossUSD: 3890000, returnsUSD: 120000, netUSD: 3770000, marginUSD: 1394900, marginPct: 37.0 },
        { category: 'ENERGIZANTES Y TES', units: 142000, grossUSD: 2450000, returnsUSD: 95000, netUSD: 2355000, marginUSD: 918450, marginPct: 39.0 },
        { category: 'LICORES Y MALTAS', units: 118000, grossUSD: 2120000, returnsUSD: 110000, netUSD: 2010000, marginUSD: 502500, marginPct: 25.0 },
        { category: 'OTROS INSUMOS', units: 85400, grossUSD: 1540100, returnsUSD: 64680, netUSD: 1475420, marginUSD: 203696, marginPct: 13.8 }
    ],

    topSuppliers: [
        { id: 'EXT5637595', name: 'DANA IMPORT & EXPORT SL', orders: 8, units: 3370, spendUSD: 1649626, fillRate: 98.5 },
        { id: 'EXT3056409', name: 'RETYCOL INTERNATIONAL LLC', orders: 2, units: 798, spendUSD: 472000, fillRate: 100.0 },
        { id: 'EXT7206337', name: 'MERX INTERNATIONAL', orders: 25, units: 147735, spendUSD: 215474, fillRate: 95.2 },
        { id: 'J002612967', name: 'FABRICA DE PLASTICOS CORONA, C.A.', orders: 26, units: 510119412, spendUSD: 142033, fillRate: 94.8 },
        { id: 'J000792712', name: 'FORMACOL VENEZUELA, C.A.', orders: 50, units: 24159226, spendUSD: 55541, fillRate: 96.0 }
    ],

    pnlWaterfall: [
        { label: 'Ingresos Netos', amountUSD: 14850420, isTotal: false, isNegative: false },
        { label: 'Costo Ventas (COGS)', amountUSD: -9682474, isTotal: false, isNegative: true },
        { label: 'Utilidad Bruta', amountUSD: 5167946, isTotal: true, isNegative: false },
        { label: 'Gastos OPEX', amountUSD: -2840100, isTotal: false, isNegative: true },
        { label: 'Utilidad Neta P&L', amountUSD: 2327846, isTotal: true, isNegative: false }
    ],

    cashCycle: {
        dso: 38.5,
        dio: 42.5,
        dpo: 45.0,
        ccc: 36.0
    },

    oeeBreakdown: [
        { plant: 'Planta Principal Valencia', availability: 92.5, performance: 91.0, quality: 98.2, oee: 82.6 },
        { plant: 'Planta Maracaibo', availability: 89.0, performance: 93.5, quality: 97.5, oee: 81.1 },
        { plant: 'Planta Caracas Envasado', availability: 94.0, performance: 90.5, quality: 98.5, oee: 83.8 }
    ],

    scrapPareto: [
        { category: 'Envases Defectuosos', scrapUSD: 18500, cumPct: 42.0 },
        { category: 'Perdida Llenado Falla Sello', scrapUSD: 12400, cumPct: 70.2 },
        { category: 'Purga de Maquina Cambio Sabor', scrapUSD: 7800, cumPct: 87.9 },
        { category: 'Materia Prima Vencida', scrapUSD: 5300, cumPct: 100.0 }
    ],

    inventoryHealth: [
        { status: 'Stock Óptimo (15-60 días)', count: 520, valueUSD: 2680000 },
        { status: 'Sobreinventario (> 60 días)', count: 145, valueUSD: 942500 },
        { status: 'Riesgo de Rotura (< 15 días)', count: 62, valueUSD: 185000 },
        { status: 'Sin Movimiento / Obsoleto', count: 18, valueUSD: 35000 }
    ],

    inventoryABC: [
        { class: 'Clase A (Alto Valor)', skusPct: 20, valueUSD: 3074000, valuePct: 80.0 },
        { class: 'Clase B (Valor Medio)', skusPct: 30, valueUSD: 576375, valuePct: 15.0 },
        { class: 'Clase C (Bajo Valor)', skusPct: 50, valueUSD: 192125, valuePct: 5.0 }
    ],

    etlAuditLogs: [
        { id: 21, process: 'ETL_Carga_Diaria_DW_PB', status: 'EXITOSO', start: '2026-08-11 10:48:31', end: '2026-08-11 10:49:25', duration: 54, msg: 'Carga completa de 11 Dim y 4 Facts exitosa (2.2M registros).' },
        { id: 20, process: 'ETL_Carga_Diaria_DW_PB', status: 'EXITOSO', start: '2026-08-11 10:43:36', end: '2026-08-11 10:44:59', duration: 83, msg: 'Proceso diario finalizado con éxito.' },
        { id: 19, process: 'ETL_Carga_Diaria_DW_PB', status: 'ERROR', start: '2026-08-11 10:40:29', end: '2026-08-11 10:40:30', duration: 1, msg: 'Incorrect syntax near keyword WITH (Resuelto).' }
    ]
};
