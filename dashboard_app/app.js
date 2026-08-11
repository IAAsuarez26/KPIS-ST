/* ===============================================================================
   ANTIGRAVITY BI SUITE - EXECUTIVE APPLICATION LOGIC & CHART.JS ENGINE
   =============================================================================== */

document.addEventListener('DOMContentLoaded', () => {
    // State Management
    let currentCurrency = 'USD';
    let currentPeriod = 'all'; // 'all', '2025', '2026'
    let currentTheme = 'dark'; // 'dark', 'light'
    let currentTab = 'overview';
    const chartInstances = {};

    // DOM Elements
    const tabButtons = document.querySelectorAll('.nav-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    const tabTitle = document.getElementById('tab-title');
    const tabSubtitle = document.getElementById('tab-subtitle');
    const btnUSD = document.getElementById('btn-usd');
    const btnVEF = document.getElementById('btn-vef');
    const filterPeriodSelect = document.getElementById('filter-period');
    const btnRefresh = document.getElementById('btn-refresh');
    const btnThemeToggle = document.getElementById('btn-theme-toggle');
    const themeIcon = document.getElementById('theme-icon');
    const searchVentasInput = document.getElementById('search-table-ventas');

    // Tab Subtitles Map
    const tabTitlesMap = {
        overview: { title: 'Executive Overview', subtitle: 'Visión Consolidada 360° del Desempeño Empresarial' },
        ventas: { title: 'Ventas y Rentabilidad', subtitle: 'Análisis Comercial, Matriz BCG y Regla de Pareto de Clientes' },
        compras: { title: 'Compras y Proveedores', subtitle: 'Evaluación de Abastecimiento, Fill Rate % y Variación PPV' },
        finanzas: { title: 'Finanzas y P&L', subtitle: 'Estado de Ganancias y Pérdidas, Balance General y Ciclo de Efectivo' },
        produccion: { title: 'Producción y Planta', subtitle: 'Eficiencia OEE, Control de Mermas/Scrap y Horas Hombre/Máquina' },
        inventario: { title: 'Inventario y Stock', subtitle: 'Valorización de Stock, Días de Cobertura (DOH) y Clasificación ABC' },
        sistemas: { title: 'Gobernanza TI & ETLs', subtitle: 'Monitoreo de SLAs de Carga, Auditoría de Errores y Salud de Base de Datos' }
    };

    // Helper: Currency Formatter
    function formatMoney(amount, currency = currentCurrency) {
        if (currency === 'VEF') {
            const valVEF = amount * DW_DATA.exchangeRate;
            return 'Bs. ' + Math.round(valVEF).toLocaleString('es-VE');
        }
        return '$' + Math.round(amount).toLocaleString('en-US');
    }

    // Helper: Percentage Formatter
    function formatPct(val) {
        return val.toFixed(1) + '%';
    }

    // Navigation Handler
    tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const targetTab = btn.getAttribute('data-tab');
            if (targetTab === currentTab) return;

            tabButtons.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            btn.classList.add('active');
            const targetContent = document.getElementById(`tab-${targetTab}`);
            if (targetContent) targetContent.classList.add('active');

            currentTab = targetTab;
            if (tabTitlesMap[currentTab]) {
                tabTitle.textContent = tabTitlesMap[currentTab].title;
                tabSubtitle.textContent = tabTitlesMap[currentTab].subtitle;
            }

            renderChartsForTab(currentTab);
        });
    });

    // Theme Switcher Handler (Oscuro / Claro)
    if (btnThemeToggle) {
        btnThemeToggle.addEventListener('click', () => {
            if (currentTheme === 'dark') {
                currentTheme = 'light';
                document.body.classList.remove('dark-theme');
                document.body.classList.add('light-theme');
                themeIcon.setAttribute('data-lucide', 'moon');
            } else {
                currentTheme = 'dark';
                document.body.classList.remove('light-theme');
                document.body.classList.add('dark-theme');
                themeIcon.setAttribute('data-lucide', 'sun');
            }
            if (window.lucide) window.lucide.createIcons();
            
            // Re-render charts with theme adapted colors
            Chart.defaults.color = currentTheme === 'dark' ? '#9CA3AF' : '#475569';
            renderChartsForTab(currentTab, true);
        });
    }

    // Currency Switcher Handler
    btnUSD.addEventListener('click', () => setCurrency('USD'));
    btnVEF.addEventListener('click', () => setCurrency('VEF'));

    function setCurrency(currency) {
        if (currentCurrency === currency) return;
        currentCurrency = currency;

        if (currency === 'USD') {
            btnUSD.classList.add('active');
            btnVEF.classList.remove('active');
        } else {
            btnVEF.classList.add('active');
            btnUSD.classList.remove('active');
        }

        updateAllValues();
        renderChartsForTab(currentTab, true);
    }

    // Period Filter Listener
    if (filterPeriodSelect) {
        filterPeriodSelect.addEventListener('change', (e) => {
            setPeriod(e.target.value);
        });
    }

    if (btnRefresh) {
        btnRefresh.addEventListener('click', () => {
            updateAllValues();
            renderChartsForTab(currentTab, true);
        });
    }

    function setPeriod(period) {
        currentPeriod = period;
        updateAllValues();
        renderChartsForTab(currentTab, true);
    }

    // Update Formatted Text Values
    function updateAllValues() {
        const s = DW_DATA.summary[currentPeriod] || DW_DATA.summary.all;
        
        // Overview KPIs
        document.getElementById('ov-ventas').textContent = formatMoney(s.totalSalesUSD);
        document.getElementById('ov-margen').textContent = formatPct(s.marginPct);
        document.getElementById('ov-margen-val').textContent = formatMoney(s.grossMarginUSD);
        document.getElementById('ov-compras').textContent = formatMoney(s.totalPurchasesUSD);
        document.getElementById('ov-oee').textContent = formatPct(s.oeePct);

        // Ventas KPIs
        document.getElementById('v-facturado').textContent = formatMoney(s.facturadoUSD);
        document.getElementById('v-devoluciones').textContent = formatMoney(s.devolucionesUSD);
        document.getElementById('v-neta').textContent = formatMoney(s.totalSalesUSD);
        document.getElementById('v-ticket').textContent = formatMoney(s.ticketUSD);

        // Compras KPIs
        document.getElementById('c-gasto').textContent = formatMoney(s.totalPurchasesUSD);

        // Finanzas KPIs
        document.getElementById('f-ingresos').textContent = formatMoney(s.totalSalesUSD);
        document.getElementById('f-cogs').textContent = formatMoney(s.cogsUSD);
        document.getElementById('f-opex').textContent = formatMoney(s.opexUSD);
        document.getElementById('f-neto').textContent = formatMoney(s.netProfitUSD);

        // Inventario KPIs
        document.getElementById('i-valor').textContent = formatMoney(s.totalInventoryUSD);

        // Populate Table
        renderVentasTable();
        renderEtlAuditTable();
    }

    // Render Ventas Table
    function renderVentasTable(filterTerm = '') {
        const tbody = document.querySelector('#table-ventas tbody');
        if (!tbody) return;
        tbody.innerHTML = '';

        const dataSet = DW_DATA.salesCategoriesTable[currentPeriod] || DW_DATA.salesCategoriesTable.all;

        dataSet.forEach(row => {
            if (filterTerm && !row.category.toLowerCase().includes(filterTerm.toLowerCase())) return;

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong>${row.category}</strong></td>
                <td>${row.units.toLocaleString()} Unidades</td>
                <td>${formatMoney(row.grossUSD)}</td>
                <td style="color: var(--accent-red);">${formatMoney(row.returnsUSD)}</td>
                <td><strong>${formatMoney(row.netUSD)}</strong></td>
                <td>${formatMoney(row.marginUSD)}</td>
                <td><span class="status-badge exitoso">${formatPct(row.marginPct)}</span></td>
            `;
            tbody.appendChild(tr);
        });
    }

    // Render ETL Audit Table
    function renderEtlAuditTable() {
        const tbody = document.querySelector('#table-etl-audit tbody');
        if (!tbody) return;
        tbody.innerHTML = '';

        DW_DATA.etlAuditLogs.forEach(log => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>#${log.id}</td>
                <td><strong>${log.process}</strong></td>
                <td><span class="status-badge ${log.status.toLowerCase()}">${log.status}</span></td>
                <td>${log.start}</td>
                <td>${log.end}</td>
                <td>${log.duration} seg</td>
                <td>${log.msg}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    if (searchVentasInput) {
        searchVentasInput.addEventListener('input', (e) => {
            renderVentasTable(e.target.value);
        });
    }

    // ===============================================================================
    // CHART.JS ENGINE INITIALIZATION
    // ===============================================================================

    Chart.defaults.color = '#9CA3AF';
    Chart.defaults.font.family = "'Inter', sans-serif";

    function renderChartsForTab(tab, forceRebuild = false) {
        if (tab === 'overview') {
            initOverviewCharts(forceRebuild);
        } else if (tab === 'ventas') {
            initVentasCharts(forceRebuild);
        } else if (tab === 'compras') {
            initComprasCharts(forceRebuild);
        } else if (tab === 'finanzas') {
            initFinanzasCharts(forceRebuild);
        } else if (tab === 'produccion') {
            initProduccionCharts(forceRebuild);
        } else if (tab === 'inventario') {
            initInventarioCharts(forceRebuild);
        }
    }

    function destroyChart(key) {
        if (chartInstances[key]) {
            chartInstances[key].destroy();
            delete chartInstances[key];
        }
    }

    // Filter Trend Data by Period
    function getFilteredTrendData() {
        if (currentPeriod === 'all') return DW_DATA.monthlySalesTrend;
        return DW_DATA.monthlySalesTrend.filter(d => d.year.toString() === currentPeriod);
    }

    // 0. OVERVIEW CHARTS
    function initOverviewCharts(force = false) {
        if (!force && chartInstances['ov-ventas']) return;
        destroyChart('ov-ventas');
        destroyChart('ov-compras');

        const trendData = getFilteredTrendData();
        const ctxVentas = document.getElementById('chart-ov-ventas-trend');
        if (ctxVentas) {
            chartInstances['ov-ventas'] = new Chart(ctxVentas, {
                type: 'line',
                data: {
                    labels: trendData.map(d => d.month),
                    datasets: [
                        {
                            label: `Ventas Netas (${currentCurrency})`,
                            data: trendData.map(d => currentCurrency === 'USD' ? d.salesUSD : d.salesUSD * DW_DATA.exchangeRate),
                            borderColor: '#3B82F6',
                            backgroundColor: 'rgba(59, 130, 246, 0.1)',
                            fill: true,
                            tension: 0.4
                        },
                        {
                            label: `Margen Bruto (${currentCurrency})`,
                            data: trendData.map(d => currentCurrency === 'USD' ? d.marginUSD : d.marginUSD * DW_DATA.exchangeRate),
                            borderColor: '#10B981',
                            backgroundColor: 'transparent',
                            borderDash: [5, 5],
                            tension: 0.4
                        }
                    ]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }

        const ctxCompras = document.getElementById('chart-ov-compras-pie');
        const purchasesData = DW_DATA.purchasesByCategory[currentPeriod] || DW_DATA.purchasesByCategory.all;
        if (ctxCompras) {
            chartInstances['ov-compras'] = new Chart(ctxCompras, {
                type: 'doughnut',
                data: {
                    labels: purchasesData.map(d => d.category),
                    datasets: [{
                        data: purchasesData.map(d => currentCurrency === 'USD' ? d.amountUSD : d.amountUSD * DW_DATA.exchangeRate),
                        backgroundColor: ['#8B5CF6', '#3B82F6', '#10B981', '#F59E0B', '#EF4444']
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, cutout: '65%' }
            });
        }
    }

    // 1. VENTAS CHARTS
    function initVentasCharts(force = false) {
        if (!force && chartInstances['v-bcg']) return;
        destroyChart('v-bcg');
        destroyChart('v-pareto');

        const bcgData = DW_DATA.salesBCG[currentPeriod] || DW_DATA.salesBCG.all;
        const ctxBCG = document.getElementById('chart-v-bcg');
        if (ctxBCG) {
            chartInstances['v-bcg'] = new Chart(ctxBCG, {
                type: 'bubble',
                data: {
                    datasets: bcgData.map((item, idx) => ({
                        label: item.product,
                        data: [{ x: item.volume, y: item.marginPct, r: Math.max(8, item.revenueUSD / 100000) }],
                        backgroundColor: ['#3B82F6', '#10B981', '#8B5CF6', '#F59E0B', '#EF4444', '#06B6D4', '#EC4899'][idx % 7]
                    }))
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: { title: { display: true, text: 'Volumen Vendido (Unidades)' } },
                        y: { title: { display: true, text: '% Margen de Ganancia' } }
                    }
                }
            });
        }

        const paretoData = DW_DATA.paretoCustomers[currentPeriod] || DW_DATA.paretoCustomers.all;
        const ctxPareto = document.getElementById('chart-v-pareto');
        if (ctxPareto) {
            chartInstances['v-pareto'] = new Chart(ctxPareto, {
                type: 'bar',
                data: {
                    labels: paretoData.map(c => c.name.length > 15 ? c.name.substring(0, 15) + '...' : c.name),
                    datasets: [
                        {
                            label: `Ventas ($ ${currentCurrency})`,
                            data: paretoData.map(c => currentCurrency === 'USD' ? c.salesUSD : c.salesUSD * DW_DATA.exchangeRate),
                            backgroundColor: '#3B82F6',
                            yAxisID: 'y'
                        },
                        {
                            label: '% Acumulado Pareto',
                            data: paretoData.map(c => c.cumPct),
                            borderColor: '#F59E0B',
                            type: 'line',
                            yAxisID: 'y1'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: { type: 'linear', position: 'left' },
                        y1: { type: 'linear', position: 'right', max: 100 }
                    }
                }
            });
        }
    }

    // 2. COMPRAS CHARTS
    function initComprasCharts(force = false) {
        if (!force && chartInstances['c-top-suppliers']) return;
        destroyChart('c-top-suppliers');
        destroyChart('c-fill-rate');

        const ctxTop = document.getElementById('chart-c-top-suppliers');
        if (ctxTop) {
            chartInstances['c-top-suppliers'] = new Chart(ctxTop, {
                type: 'bar',
                data: {
                    labels: DW_DATA.topSuppliers.map(s => s.name.substring(0, 18) + '..'),
                    datasets: [{
                        label: `Gasto en Compras (${currentCurrency})`,
                        data: DW_DATA.topSuppliers.map(s => currentCurrency === 'USD' ? s.spendUSD : s.spendUSD * DW_DATA.exchangeRate),
                        backgroundColor: '#8B5CF6'
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y' }
            });
        }

        const ctxFill = document.getElementById('chart-c-fill-rate');
        if (ctxFill) {
            chartInstances['c-fill-rate'] = new Chart(ctxFill, {
                type: 'bar',
                data: {
                    labels: DW_DATA.topSuppliers.map(s => s.name.substring(0, 15) + '..'),
                    datasets: [{
                        label: 'Fill Rate % (Cumplimiento)',
                        data: DW_DATA.topSuppliers.map(s => s.fillRate),
                        backgroundColor: '#10B981'
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, scales: { y: { min: 80, max: 100 } } }
            });
        }
    }

    // 3. FINANZAS CHARTS
    function initFinanzasCharts(force = false) {
        if (!force && chartInstances['f-waterfall']) return;
        destroyChart('f-waterfall');
        destroyChart('f-ccc');

        const pnlData = DW_DATA.pnlWaterfall[currentPeriod] || DW_DATA.pnlWaterfall.all;
        const ctxWaterfall = document.getElementById('chart-f-pnl-waterfall');
        if (ctxWaterfall) {
            chartInstances['f-waterfall'] = new Chart(ctxWaterfall, {
                type: 'bar',
                data: {
                    labels: pnlData.map(w => w.label),
                    datasets: [{
                        label: `Monto (${currentCurrency})`,
                        data: pnlData.map(w => currentCurrency === 'USD' ? w.amountUSD : w.amountUSD * DW_DATA.exchangeRate),
                        backgroundColor: pnlData.map(w => w.isNegative ? '#EF4444' : '#10B981')
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }

        const ctxCCC = document.getElementById('chart-f-ccc');
        if (ctxCCC) {
            const ccc = DW_DATA.cashCycle;
            chartInstances['f-ccc'] = new Chart(ctxCCC, {
                type: 'bar',
                data: {
                    labels: ['DSO (Días Cobro)', 'DIO (Días Stock)', 'DPO (Días Pago)', 'CCC (Ciclo Efectivo)'],
                    datasets: [{
                        label: 'Días Transcurridos',
                        data: [ccc.dso, ccc.dio, -ccc.dpo, ccc.ccc],
                        backgroundColor: ['#3B82F6', '#F59E0B', '#EF4444', '#10B981']
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }
    }

    // 4. PRODUCCION CHARTS
    function initProduccionCharts(force = false) {
        if (!force && chartInstances['p-oee']) return;
        destroyChart('p-oee');
        destroyChart('p-scrap');

        const ctxOEE = document.getElementById('chart-p-oee-breakdown');
        if (ctxOEE) {
            chartInstances['p-oee'] = new Chart(ctxOEE, {
                type: 'bar',
                data: {
                    labels: DW_DATA.oeeBreakdown.map(o => o.plant),
                    datasets: [
                        { label: 'Disponibilidad %', data: DW_DATA.oeeBreakdown.map(o => o.availability), backgroundColor: '#3B82F6' },
                        { label: 'Rendimiento %', data: DW_DATA.oeeBreakdown.map(o => o.performance), backgroundColor: '#F59E0B' },
                        { label: 'Calidad %', data: DW_DATA.oeeBreakdown.map(o => o.quality), backgroundColor: '#10B981' }
                    ]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }

        const ctxScrap = document.getElementById('chart-p-scrap');
        if (ctxScrap) {
            chartInstances['p-scrap'] = new Chart(ctxScrap, {
                type: 'bar',
                data: {
                    labels: DW_DATA.scrapPareto.map(s => s.category),
                    datasets: [{
                        label: `Costo Merma (${currentCurrency})`,
                        data: DW_DATA.scrapPareto.map(s => currentCurrency === 'USD' ? s.scrapUSD : s.scrapUSD * DW_DATA.exchangeRate),
                        backgroundColor: '#EF4444'
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }
    }

    // 5. INVENTARIO CHARTS
    function initInventarioCharts(force = false) {
        if (!force && chartInstances['i-health']) return;
        destroyChart('i-health');
        destroyChart('i-abc');

        const ctxHealth = document.getElementById('chart-i-health');
        if (ctxHealth) {
            chartInstances['i-health'] = new Chart(ctxHealth, {
                type: 'doughnut',
                data: {
                    labels: DW_DATA.inventoryHealth.map(h => h.status),
                    datasets: [{
                        data: DW_DATA.inventoryHealth.map(h => currentCurrency === 'USD' ? h.valueUSD : h.valueUSD * DW_DATA.exchangeRate),
                        backgroundColor: ['#10B981', '#F59E0B', '#EF4444', '#6B7280']
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, cutout: '60%' }
            });
        }

        const ctxABC = document.getElementById('chart-i-abc');
        if (ctxABC) {
            chartInstances['i-abc'] = new Chart(ctxABC, {
                type: 'bar',
                data: {
                    labels: DW_DATA.inventoryABC.map(a => a.class),
                    datasets: [{
                        label: `Valor Inmovilizado (${currentCurrency})`,
                        data: DW_DATA.inventoryABC.map(a => currentCurrency === 'USD' ? a.valueUSD : a.valueUSD * DW_DATA.exchangeRate),
                        backgroundColor: ['#3B82F6', '#8B5CF6', '#6B7280']
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }
    }

    // Initial Load
    updateAllValues();
    renderChartsForTab('overview');
});
