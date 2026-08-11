/* ===============================================================================
   ANTIGRAVITY BI SUITE - DW_PB ENTERPRISE DATASET (PERIOD-BASED MULTI-YEAR DATA)
   =============================================================================== */

const DW_DATA = {
    exchangeRate: 36.50, // Tasa Oficial VEF por USD

    // Summaries per Period
    summary: {
        all: {
            totalSalesUSD: 14850420,
            grossMarginUSD: 5167946,
            marginPct: 34.8,
            totalPurchasesUSD: 2535175,
            fillRatePct: 96.4,
            oeePct: 82.4,
            scrapPct: 2.1,
            totalInventoryUSD: 3842500,
            dohDays: 42.5,
            cogsUSD: 9682474,
            opexUSD: 2840100,
            netProfitUSD: 2327846,
            facturadoUSD: 15420100,
            devolucionesUSD: 569680,
            ticketUSD: 21.48
        },
        '2025': {
            totalSalesUSD: 12220000,
            grossMarginUSD: 4245600,
            marginPct: 34.7,
            totalPurchasesUSD: 2085000,
            fillRatePct: 95.8,
            oeePct: 81.2,
            scrapPct: 2.3,
            totalInventoryUSD: 3450000,
            dohDays: 45.0,
            cogsUSD: 7974400,
            opexUSD: 2350000,
            netProfitUSD: 1895600,
            facturadoUSD: 12680000,
            devolucionesUSD: 460000,
            ticketUSD: 20.80
        },
        '2026': {
            totalSalesUSD: 2630000,
            grossMarginUSD: 922346,
            marginPct: 35.1,
            totalPurchasesUSD: 450175,
            fillRatePct: 98.2,
            oeePct: 84.5,
            scrapPct: 1.8,
            totalInventoryUSD: 3842500,
            dohDays: 38.5,
            cogsUSD: 1707646,
            opexUSD: 490100,
            netProfitUSD: 432246,
            facturadoUSD: 2740100,
            devolucionesUSD: 109680,
            ticketUSD: 23.50
        }
    },

    monthlySalesTrend: [
        { year: 2025, month: 'Ene 2025', salesUSD: 1050000, marginUSD: 362250, marginPct: 34.5 },
        { year: 2025, month: 'Feb 2025', salesUSD: 1120000, marginUSD: 392000, marginPct: 35.0 },
        { year: 2025, month: 'Mar 2025', salesUSD: 1180000, marginUSD: 401200, marginPct: 34.0 },
        { year: 2025, month: 'Abr 2025', salesUSD: 1090000, marginUSD: 376050, marginPct: 34.5 },
        { year: 2025, month: 'May 2025', salesUSD: 1250000, marginUSD: 443750, marginPct: 35.5 },
        { year: 2025, month: 'Jun 2025', salesUSD: 1310000, marginUSD: 465050, marginPct: 35.5 },
        { year: 2025, month: 'Jul 2025', salesUSD: 1280000, marginUSD: 441600, marginPct: 34.5 },
        { year: 2025, month: 'Ago 2025', salesUSD: 1350000, marginUSD: 479250, marginPct: 35.5 },
        { year: 2025, month: 'Sep 2025', salesUSD: 1220000, marginUSD: 420900, marginPct: 34.5 },
        { year: 2025, month: 'Oct 2025', salesUSD: 1400000, marginUSD: 490000, marginPct: 35.0 },
        { year: 2025, month: 'Nov 2025', salesUSD: 1450000, marginUSD: 514750, marginPct: 35.5 },
        { year: 2025, month: 'Dic 2025', salesUSD: 1620000, marginUSD: 575100, marginPct: 35.5 },
        { year: 2026, month: 'Ene 2026', salesUSD: 1280000, marginUSD: 441600, marginPct: 34.5 },
        { year: 2026, month: 'Feb 2026', salesUSD: 1350000, marginUSD: 479250, marginPct: 35.5 }
    ],

    purchasesByCategory: {
        all: [
            { category: 'Materia Prima Importada', amountUSD: 1649626 },
            { category: 'Envases y Empaques', amountUSD: 472000 },
            { category: 'Insumos Químicos', amountUSD: 215474 },
            { category: 'Repuestos e Industriales', amountUSD: 142033 },
            { category: 'Materiales Locales', amountUSD: 55541 }
        ],
        '2025': [
            { category: 'Materia Prima Importada', amountUSD: 1350000 },
            { category: 'Envases y Empaques', amountUSD: 390000 },
            { category: 'Insumos Químicos', amountUSD: 175000 },
            { category: 'Repuestos e Industriales', amountUSD: 120000 },
            { category: 'Materiales Locales', amountUSD: 50000 }
        ],
        '2026': [
            { category: 'Materia Prima Importada', amountUSD: 299626 },
            { category: 'Envases y Empaques', amountUSD: 82000 },
            { category: 'Insumos Químicos', amountUSD: 40474 },
            { category: 'Repuestos e Industriales', amountUSD: 22033 },
            { category: 'Materiales Locales', amountUSD: 5541 }
        ]
    },

    salesBCG: {
        all: [
            { product: 'Bebida Carbonatada 2L', volume: 154000, marginPct: 42.5, revenueUSD: 1250000 },
            { product: 'Agua Mineral 500ml', volume: 220000, marginPct: 38.0, revenueUSD: 980000 },
            { product: 'Jugo Natural 1L', volume: 95000, marginPct: 31.5, revenueUSD: 640000 },
            { product: 'Te Frío Durazno 1.5L', volume: 45000, marginPct: 22.0, revenueUSD: 210000 },
            { product: 'Bebida Energizante', volume: 32000, marginPct: 45.0, revenueUSD: 480000 },
            { product: 'Soda Lima Limón 355ml', volume: 110000, marginPct: 36.0, revenueUSD: 520000 },
            { product: 'Malta Especial 250ml', volume: 88000, marginPct: 28.5, revenueUSD: 310000 }
        ],
        '2025': [
            { product: 'Bebida Carbonatada 2L', volume: 128000, marginPct: 41.8, revenueUSD: 1020000 },
            { product: 'Agua Mineral 500ml', volume: 185000, marginPct: 37.5, revenueUSD: 810000 },
            { product: 'Jugo Natural 1L', volume: 78000, marginPct: 31.0, revenueUSD: 520000 },
            { product: 'Te Frío Durazno 1.5L', volume: 38000, marginPct: 21.5, revenueUSD: 175000 },
            { product: 'Bebida Energizante', volume: 25000, marginPct: 44.0, revenueUSD: 375000 },
            { product: 'Soda Lima Limón 355ml', volume: 92000, marginPct: 35.5, revenueUSD: 430000 },
            { product: 'Malta Especial 250ml', volume: 72000, marginPct: 28.0, revenueUSD: 250000 }
        ],
        '2026': [
            { product: 'Bebida Carbonatada 2L', volume: 26000, marginPct: 44.0, revenueUSD: 230000 },
            { product: 'Agua Mineral 500ml', volume: 35000, marginPct: 39.5, revenueUSD: 170000 },
            { product: 'Jugo Natural 1L', volume: 17000, marginPct: 33.0, revenueUSD: 120000 },
            { product: 'Te Frío Durazno 1.5L', volume: 7000, marginPct: 24.0, revenueUSD: 35000 },
            { product: 'Bebida Energizante', volume: 7000, marginPct: 48.0, revenueUSD: 105000 },
            { product: 'Soda Lima Limón 355ml', volume: 18000, marginPct: 37.5, revenueUSD: 90000 },
            { product: 'Malta Especial 250ml', volume: 16000, marginPct: 30.0, revenueUSD: 60000 }
        ]
    },

    paretoCustomers: {
        all: [
            { name: 'SUPERMERCADOS PLAZA, C.A.', salesUSD: 2850400, cumPct: 19.2 },
            { name: 'DISTRIBUIDORA POLAR DE VZLA', salesUSD: 2120000, cumPct: 33.5 },
            { name: 'EXCELSIOR GAMA SUPERMERCADOS', salesUSD: 1840000, cumPct: 45.9 },
            { name: 'FARMACIA SAAS UNICENTER', salesUSD: 1250000, cumPct: 54.3 },
            { name: 'COMERCIALIZADORA MAKRO', salesUSD: 980000, cumPct: 60.9 },
            { name: 'CENTRO COMERCIAL BIDEAUX', salesUSD: 720000, cumPct: 65.7 },
            { name: 'Otros 1,137 Clientes', salesUSD: 5090020, cumPct: 100.0 }
        ],
        '2025': [
            { name: 'SUPERMERCADOS PLAZA, C.A.', salesUSD: 2350000, cumPct: 19.2 },
            { name: 'DISTRIBUIDORA POLAR DE VZLA', salesUSD: 1750000, cumPct: 33.5 },
            { name: 'EXCELSIOR GAMA SUPERMERCADOS', salesUSD: 1520000, cumPct: 45.9 },
            { name: 'FARMACIA SAAS UNICENTER', salesUSD: 1030000, cumPct: 54.3 },
            { name: 'COMERCIALIZADORA MAKRO', salesUSD: 810000, cumPct: 60.9 },
            { name: 'CENTRO COMERCIAL BIDEAUX', salesUSD: 590000, cumPct: 65.7 },
            { name: 'Otros 1,137 Clientes', salesUSD: 4170000, cumPct: 100.0 }
        ],
        '2026': [
            { name: 'SUPERMERCADOS PLAZA, C.A.', salesUSD: 500400, cumPct: 19.0 },
            { name: 'DISTRIBUIDORA POLAR DE VZLA', salesUSD: 370000, cumPct: 33.1 },
            { name: 'EXCELSIOR GAMA SUPERMERCADOS', salesUSD: 320000, cumPct: 45.2 },
            { name: 'FARMACIA SAAS UNICENTER', salesUSD: 220000, cumPct: 53.6 },
            { name: 'COMERCIALIZADORA MAKRO', salesUSD: 170000, cumPct: 60.1 },
            { name: 'CENTRO COMERCIAL BIDEAUX', salesUSD: 130000, cumPct: 65.0 },
            { name: 'Otros 1,137 Clientes', salesUSD: 919600, cumPct: 100.0 }
        ]
    },

    salesCategoriesTable: {
        all: [
            { category: 'BEBIDAS CARBONATADAS', units: 485200, grossUSD: 5420000, returnsUSD: 180000, netUSD: 5240000, marginUSD: 2148400, marginPct: 41.0 },
            { category: 'AGUAS Y JUGOS', units: 395100, grossUSD: 3890000, returnsUSD: 120000, netUSD: 3770000, marginUSD: 1394900, marginPct: 37.0 },
            { category: 'ENERGIZANTES Y TES', units: 142000, grossUSD: 2450000, returnsUSD: 95000, netUSD: 2355000, marginUSD: 918450, marginPct: 39.0 },
            { category: 'LICORES Y MALTAS', units: 118000, grossUSD: 2120000, returnsUSD: 110000, netUSD: 2010000, marginUSD: 502500, marginPct: 25.0 },
            { category: 'OTROS INSUMOS', units: 85400, grossUSD: 1540100, returnsUSD: 64680, netUSD: 1475420, marginUSD: 203696, marginPct: 13.8 }
        ],
        '2025': [
            { category: 'BEBIDAS CARBONATADAS', units: 398000, grossUSD: 4450000, returnsUSD: 145000, netUSD: 4305000, marginUSD: 1756440, marginPct: 40.8 },
            { category: 'AGUAS Y JUGOS', units: 324000, grossUSD: 3190000, returnsUSD: 98000, netUSD: 3092000, marginUSD: 1137856, marginPct: 36.8 },
            { category: 'ENERGIZANTES Y TES', units: 116000, grossUSD: 2010000, returnsUSD: 78000, netUSD: 1932000, marginUSD: 749616, marginPct: 38.8 },
            { category: 'LICORES Y MALTAS', units: 96000, grossUSD: 1740000, returnsUSD: 90000, netUSD: 1650000, marginUSD: 409200, marginPct: 24.8 },
            { category: 'OTROS INSUMOS', units: 70000, grossUSD: 1290000, returnsUSD: 49000, netUSD: 1241000, marginUSD: 167535, marginPct: 13.5 }
        ],
        '2026': [
            { category: 'BEBIDAS CARBONATADAS', units: 87200, grossUSD: 970000, returnsUSD: 35000, netUSD: 935000, marginUSD: 391960, marginPct: 41.9 },
            { category: 'AGUAS Y JUGOS', units: 71100, grossUSD: 700000, returnsUSD: 22000, netUSD: 678000, marginUSD: 257044, marginPct: 37.9 },
            { category: 'ENERGIZANTES Y TES', units: 26000, grossUSD: 440000, returnsUSD: 17000, netUSD: 423000, marginUSD: 168834, marginPct: 39.9 },
            { category: 'LICORES Y MALTAS', units: 22000, grossUSD: 380000, returnsUSD: 20000, netUSD: 360000, marginUSD: 93300, marginPct: 25.9 },
            { category: 'OTROS INSUMOS', units: 15400, grossUSD: 250100, returnsUSD: 15680, netUSD: 234420, marginUSD: 36161, marginPct: 15.4 }
        ]
    },

    topSuppliers: [
        { id: 'EXT5637595', name: 'DANA IMPORT & EXPORT SL', orders: 8, units: 3370, spendUSD: 1649626, fillRate: 98.5 },
        { id: 'EXT3056409', name: 'RETYCOL INTERNATIONAL LLC', orders: 2, units: 798, spendUSD: 472000, fillRate: 100.0 },
        { id: 'EXT7206337', name: 'MERX INTERNATIONAL', orders: 25, units: 147735, spendUSD: 215474, fillRate: 95.2 },
        { id: 'J002612967', name: 'FABRICA DE PLASTICOS CORONA, C.A.', orders: 26, units: 510119412, spendUSD: 142033, fillRate: 94.8 },
        { id: 'J000792712', name: 'FORMACOL VENEZUELA, C.A.', orders: 50, units: 24159226, spendUSD: 55541, fillRate: 96.0 }
    ],

    pnlWaterfall: {
        all: [
            { label: 'Ingresos Netos', amountUSD: 14850420, isTotal: false, isNegative: false },
            { label: 'Costo Ventas (COGS)', amountUSD: -9682474, isTotal: false, isNegative: true },
            { label: 'Utilidad Bruta', amountUSD: 5167946, isTotal: true, isNegative: false },
            { label: 'Gastos OPEX', amountUSD: -2840100, isTotal: false, isNegative: true },
            { label: 'Utilidad Neta P&L', amountUSD: 2327846, isTotal: true, isNegative: false }
        ],
        '2025': [
            { label: 'Ingresos Netos', amountUSD: 12220000, isTotal: false, isNegative: false },
            { label: 'Costo Ventas (COGS)', amountUSD: -7974400, isTotal: false, isNegative: true },
            { label: 'Utilidad Bruta', amountUSD: 4245600, isTotal: true, isNegative: false },
            { label: 'Gastos OPEX', amountUSD: -2350000, isTotal: false, isNegative: true },
            { label: 'Utilidad Neta P&L', amountUSD: 1895600, isTotal: true, isNegative: false }
        ],
        '2026': [
            { label: 'Ingresos Netos', amountUSD: 2630000, isTotal: false, isNegative: false },
            { label: 'Costo Ventas (COGS)', amountUSD: -1707646, isTotal: false, isNegative: true },
            { label: 'Utilidad Bruta', amountUSD: 922346, isTotal: true, isNegative: false },
            { label: 'Gastos OPEX', amountUSD: -490100, isTotal: false, isNegative: true },
            { label: 'Utilidad Neta P&L', amountUSD: 432246, isTotal: true, isNegative: false }
        ]
    },

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
