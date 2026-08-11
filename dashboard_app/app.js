/* ===============================================================================
   ANTIGRAVITY BI SUITE - EXECUTIVE APPLICATION LOGIC & CHART.JS ENGINE
   =============================================================================== */

document.addEventListener('DOMContentLoaded', () => {
    // State Management
    let currentCurrency = 'USD';
    let currentPeriod = 'all'; // 'all', '2015' .. '2026'
    let currentTheme = 'dark'; // 'dark', 'light'
    let isSidebarCollapsed = false;
    let currentTab = 'overview';
    const chartInstances = {};

    // DOM Elements
    const appLayout = document.getElementById('app-layout');
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
    const btnSidebarToggle = document.getElementById('btn-sidebar-toggle');
    const sidebarToggleIcon = document.getElementById('sidebar-toggle-icon');
    const searchVentasInput = document.getElementById('search-table-ventas');

    // Tab Subtitles Map
    const tabTitlesMap = {
        overview: { title: 'Executive Overview', subtitle: 'Visión Consolidada 360° del Desempeño Empresarial' },
        ventas: { title: 'Ventas y Rentabilidad', subtitle: 'Análisis Comercial, Matriz BCG y Regla de Pareto de Clientes' },
        compras: { title: 'Compras y Proveedores', subtitle: 'Evaluación de Abastecimiento, Fill Rate % y Variación PPV' },
        finanzas: { title: 'Finanzas y P&L', subtitle: 'Estado de Ganancias y Pérdidas, Balance General y Ciclo de Efectivo' },
        produccion: { title: 'Producción y Liberación de Productos', subtitle: 'Eficiencia OEE, Embudo de Liberación para Ventas (ATP) y Control de Mermas' },
        inventario: { title: 'Inventario y Stock', subtitle: 'Valorización de Stock Liberado/Retenido, Cobertura (DOH) y Clasificación ABC' },
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

    // Sidebar Collapsible Toggle Handler
    if (btnSidebarToggle) {
        btnSidebarToggle.addEventListener('click', () => {
            isSidebarCollapsed = !isSidebarCollapsed;
            if (isSidebarCollapsed) {
                appLayout.classList.add('sidebar-collapsed');
                sidebarToggleIcon.setAttribute('data-lucide', 'panel-left-open');
            } else {
                appLayout.classList.remove('sidebar-collapsed');
                sidebarToggleIcon.setAttribute('data-lucide', 'panel-left-close');
            }
            if (window.lucide) window.lucide.createIcons();

            // Resize charts smoothly
            setTimeout(() => {
                window.dispatchEvent(new Event('resize'));
            }, 300);
        });
    }

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

        // Produccion & Liberacion KPIs
        document.getElementById('p-oee').textContent = formatPct(s.oeePct);
        document.getElementById('p-release-pct').textContent = formatPct(s.onTimeReleasePct);
        document.getElementById('p-released-val').textContent = formatMoney(s.releasedStockUSD);
        document.getElementById('p-hold-days').textContent = s.holdDays + ' Días';

        // Inventario KPIs
        document.getElementById('i-valor').textContent = formatMoney(s.totalInventoryUSD);
        document.getElementById('i-liberado-val').textContent = formatMoney(s.releasedStockUSD);
        document.getElementById('i-retenido-val').textContent = formatMoney(s.onHoldStockUSD);

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

    // 4. PRODUCCION & LIBERACION CHARTS
    function initProduccionCharts(force = false) {
        if (!force && chartInstances['p-release-funnel']) return;
        destroyChart('p-release-funnel');
        destroyChart('p-oee');

        const ctxFunnel = document.getElementById('chart-p-release-funnel');
        if (ctxFunnel) {
            chartInstances['p-release-funnel'] = new Chart(ctxFunnel, {
                type: 'bar',
                data: {
                    labels: DW_DATA.productReleaseFunnel.map(f => f.stage),
                    datasets: [{
                        label: 'Unidades de Producto Terminadas',
                        data: DW_DATA.productReleaseFunnel.map(f => f.units),
                        backgroundColor: ['#3B82F6', '#8B5CF6', '#F59E0B', '#10B981']
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y' }
            });
        }

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
    }

    // 6. DW_CCR INTERACTIVE DASHBOARD & COMPARISON ENGINE
    let ccrYear = 'all';
    let ccrMonth = 'all';
    let ccrCompare = 'none';

    const filterYearSelect = document.getElementById('filter-year');
    const filterMonthSelect = document.getElementById('filter-month');
    const filterCompareSelect = document.getElementById('filter-compare');

    tabTitlesMap['ccr-soporte'] = { 
        title: 'Atención de Tickets & KPIs DW_CCR', 
        subtitle: 'Monitoreo Interactivo de Métricas, SLAs y Comparativa YoY / MoM' 
    };

    if (filterYearSelect) {
        filterYearSelect.addEventListener('change', (e) => {
            ccrYear = e.target.value;
            updateDWCCRDashboard();
        });
    }
    if (filterMonthSelect) {
        filterMonthSelect.addEventListener('change', (e) => {
            ccrMonth = e.target.value;
            updateDWCCRDashboard();
        });
    }
    if (filterCompareSelect) {
        filterCompareSelect.addEventListener('change', (e) => {
            ccrCompare = e.target.value;
            updateDWCCRDashboard();
        });
    }

    function updateDWCCRDashboard() {
        if (typeof DW_CCR_LIVE_DATA === 'undefined') return;

        const allTrend = DW_CCR_LIVE_DATA.monthlyTrend;

        let filteredTrend = allTrend.filter(item => {
            let matchYear = (ccrYear === 'all') || (item.year == ccrYear);
            let matchMonth = (ccrMonth === 'all') || (item.monthNum == ccrMonth);
            return matchYear && matchMonth;
        });

        if (filteredTrend.length === 0) filteredTrend = allTrend;

        let totalTickets = filteredTrend.reduce((sum, i) => sum + i.totalTickets, 0);
        let ticketsCerrados = filteredTrend.reduce((sum, i) => sum + i.ticketsCerrados, 0);
        let ticketsAbiertos = (ccrYear === 'all' && ccrMonth === 'all') ? DW_CCR_LIVE_DATA.summaryAll.ticketsAbiertos : (totalTickets - ticketsCerrados);
        
        let avgSLA = filteredTrend.length > 0 ? (filteredTrend.reduce((sum, i) => sum + i.pctSLA, 0) / filteredTrend.length) : DW_CCR_LIVE_DATA.summaryAll.pctSLA;
        let avgMTTR = filteredTrend.length > 0 ? (filteredTrend.reduce((sum, i) => sum + i.mttrHoras, 0) / filteredTrend.length) : DW_CCR_LIVE_DATA.summaryAll.mttrHoras;
        let closureRate = totalTickets > 0 ? (ticketsCerrados / totalTickets) * 100 : 99.2;

        let compTrend = [];
        let compLabelText = 'Sin Comparación';

        if (ccrCompare === 'yoy') {
            let refYear = (ccrYear === 'all') ? 2026 : parseInt(ccrYear);
            let prevYear = refYear - 1;
            compLabelText = `Comparando ${refYear} vs ${prevYear} (YoY)`;
            compTrend = allTrend.filter(item => item.year == prevYear && (ccrMonth === 'all' || item.monthNum == ccrMonth));
        } else if (ccrCompare === 'mom') {
            let refMonth = (ccrMonth === 'all') ? 12 : parseInt(ccrMonth);
            let prevMonth = refMonth === 1 ? 12 : refMonth - 1;
            let refYear = (ccrYear === 'all') ? 2025 : parseInt(ccrYear);
            if (refMonth === 1) refYear -= 1;
            compLabelText = `Comparando Mes ${refMonth} vs Mes ${prevMonth} (MoM)`;
            compTrend = allTrend.filter(item => item.monthNum == prevMonth && (ccrYear === 'all' || item.year == refYear));
        } else {
            compLabelText = `Filtro Activo: ${ccrYear === 'all' ? 'Histórico Completo' : 'Año ' + ccrYear} ${ccrMonth === 'all' ? '' : '/ Mes ' + ccrMonth}`;
        }

        let compTickets = compTrend.reduce((sum, i) => sum + i.totalTickets, 0);
        let compSLA = compTrend.length > 0 ? (compTrend.reduce((sum, i) => sum + i.pctSLA, 0) / compTrend.length) : avgSLA;
        let compMTTR = compTrend.length > 0 ? (compTrend.reduce((sum, i) => sum + i.mttrHoras, 0) / compTrend.length) : avgMTTR;

        let totalDiffPct = compTickets > 0 ? (((totalTickets - compTickets) / compTickets) * 100) : 0;
        let slaDiffPts = avgSLA - compSLA;
        let mttrDiffPct = compMTTR > 0 ? (((avgMTTR - compMTTR) / compMTTR) * 100) : 0;

        const bannerText = document.getElementById('ccr-banner-text');
        if (bannerText) bannerText.textContent = compLabelText;

        const elTotal = document.getElementById('kpi-ccr-total');
        if (elTotal) elTotal.textContent = totalTickets.toLocaleString('en-US');

        const elCierre = document.getElementById('kpi-ccr-cierre');
        if (elCierre) elCierre.textContent = closureRate.toFixed(1) + '%';

        const elSLA = document.getElementById('kpi-ccr-sla');
        if (elSLA) elSLA.textContent = avgSLA.toFixed(1) + '%';

        const elMTTR = document.getElementById('kpi-ccr-mttr');
        if (elMTTR) elMTTR.textContent = avgMTTR.toFixed(1) + ' h';

        const elBacklog = document.getElementById('kpi-ccr-backlog');
        if (elBacklog) elBacklog.textContent = ticketsAbiertos;

        const badgeTotal = document.getElementById('badge-ccr-total');
        if (badgeTotal) {
            if (ccrCompare !== 'none' && compTickets > 0) {
                let sign = totalDiffPct >= 0 ? '+' : '';
                badgeTotal.className = `kpi-badge ${totalDiffPct >= 0 ? 'positive' : 'warning'}`;
                badgeTotal.innerHTML = `${sign}${totalDiffPct.toFixed(1)}% vs Prev`;
            } else {
                badgeTotal.className = 'kpi-badge neutral';
                badgeTotal.textContent = `${totalTickets.toLocaleString('en-US')} Registros`;
            }
        }

        const badgeSLA = document.getElementById('badge-ccr-sla');
        if (badgeSLA) {
            if (ccrCompare !== 'none' && compTrend.length > 0) {
                let sign = slaDiffPts >= 0 ? '+' : '';
                badgeSLA.className = `kpi-badge ${slaDiffPts >= 0 ? 'positive' : 'warning'}`;
                badgeSLA.innerHTML = `${sign}${slaDiffPts.toFixed(1)} pts vs Prev`;
            } else {
                badgeSLA.className = 'kpi-badge positive';
                badgeSLA.innerHTML = '<i data-lucide="arrow-up-right"></i> Meta: 95%';
            }
        }

        const badgeMTTR = document.getElementById('badge-ccr-mttr');
        if (badgeMTTR) {
            if (ccrCompare !== 'none' && compTrend.length > 0) {
                let sign = mttrDiffPct <= 0 ? '' : '+';
                badgeMTTR.className = `kpi-badge ${mttrDiffPct <= 0 ? 'positive' : 'warning'}`;
                badgeMTTR.innerHTML = `${sign}${mttrDiffPct.toFixed(1)}% vs Prev`;
            } else {
                badgeMTTR.className = 'kpi-badge neutral';
                badgeMTTR.textContent = `~${(avgMTTR / 24).toFixed(1)} Días`;
            }
        }

        renderCCRTrendChart(filteredTrend, compTrend);
        renderCCRTopicsChart(DW_CCR_LIVE_DATA.topics);
        renderCCRAgentsChart(DW_CCR_LIVE_DATA.agents);
        renderCCRStatusChart();
        renderCCRTopicsTable(DW_CCR_LIVE_DATA.topics, totalTickets);
        renderCCRAgentsTable(DW_CCR_LIVE_DATA.agents, totalTickets);
        renderCCRAuditTable(DW_CCR_LIVE_DATA.auditLog);
    }

    function renderCCRTrendChart(filteredTrend, compTrend) {
        destroyChart('ccr-trend');
        const ctx = document.getElementById('chart-ccr-trend');
        if (!ctx) return;

        let labels = filteredTrend.map(i => `${i.monthName.substring(0,3)} ${i.year}`);
        let datasets = [{
            label: 'Tickets Período Seleccionado',
            data: filteredTrend.map(i => i.totalTickets),
            borderColor: '#3B82F6',
            backgroundColor: 'rgba(59, 130, 246, 0.15)',
            borderWidth: 3,
            fill: true,
            tension: 0.3
        }];

        if (ccrCompare !== 'none' && compTrend.length > 0) {
            datasets.push({
                label: 'Tickets Período Comparación',
                data: compTrend.map(i => i.totalTickets),
                borderColor: '#F59E0B',
                borderDash: [5, 5],
                borderWidth: 2,
                fill: false,
                tension: 0.3
            });
        }

        chartInstances['ccr-trend'] = new Chart(ctx, {
            type: 'line',
            data: { labels, datasets },
            options: { responsive: true, maintainAspectRatio: false }
        });
    }

    function renderCCRTopicsChart(topicsData) {
        destroyChart('ccr-topics');
        const ctx = document.getElementById('chart-ccr-topics');
        if (!ctx) return;

        let top5 = topicsData.slice(0, 5);
        chartInstances['ccr-topics'] = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: top5.map(t => t.name),
                datasets: [{
                    data: top5.map(t => t.count),
                    backgroundColor: ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444']
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, cutout: '65%' }
        });
    }

    function renderCCRAgentsChart(agentsData) {
        destroyChart('ccr-agents');
        const ctx = document.getElementById('chart-ccr-agents');
        if (!ctx) return;

        let topAgents = agentsData.slice(0, 7);
        chartInstances['ccr-agents'] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: topAgents.map(a => a.name),
                datasets: [{
                    label: 'Tickets Atendidos',
                    data: topAgents.map(a => a.count),
                    backgroundColor: '#8B5CF6'
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y' }
        });
    }

    function renderCCRStatusChart() {
        destroyChart('ccr-status');
        const ctx = document.getElementById('chart-ccr-status');
        if (!ctx) return;

        chartInstances['ccr-status'] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Cerrados / Resueltos', 'Abiertos / Backlog', 'Vencidos SLA'],
                datasets: [{
                    label: 'Cantidad de Tickets',
                    data: [3133, 24, 24],
                    backgroundColor: ['#10B981', '#3B82F6', '#EF4444']
                }]
            },
            options: { responsive: true, maintainAspectRatio: false }
        });
    }

    function renderCCRTopicsTable(topicsData, totalTickets) {
        const tbody = document.querySelector('#table-ccr-topics tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        let tot = totalTickets > 0 ? totalTickets : 3157;

        topicsData.forEach(t => {
            let pct = ((t.count / tot) * 100).toFixed(1);
            let row = `<tr>
                <td><strong>${t.name}</strong></td>
                <td>${t.count.toLocaleString()}</td>
                <td><span class="badge-tag cyan">${pct}%</span></td>
                <td>${t.mttr} h</td>
            </tr>`;
            tbody.innerHTML += row;
        });
    }

    function renderCCRAgentsTable(agentsData, totalTickets) {
        const tbody = document.querySelector('#table-ccr-agents tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        let tot = totalTickets > 0 ? totalTickets : 3157;

        agentsData.forEach(a => {
            let pct = ((a.count / tot) * 100).toFixed(1);
            let row = `<tr>
                <td><strong>${a.name}</strong></td>
                <td>${a.count.toLocaleString()}</td>
                <td><span class="badge-tag purple">${pct}%</span></td>
                <td>${a.vencidos}</td>
                <td>${a.mttr} h</td>
            </tr>`;
            tbody.innerHTML += row;
        });
    }

    function renderCCRAuditTable(auditLog) {
        const tbody = document.querySelector('#table-ccr-audit tbody');
        if (!tbody) return;
        tbody.innerHTML = '';

        auditLog.forEach(log => {
            let statusClass = log.estado === 'SUCCESS' ? 'positive' : 'warning';
            let row = `<tr>
                <td><strong>#${log.logId}</strong></td>
                <td>${log.proceso}</td>
                <td>${log.paso}</td>
                <td>${log.inicio}</td>
                <td>${log.fin}</td>
                <td><span class="kpi-badge ${statusClass}">${log.estado}</span></td>
                <td>${log.registros.toLocaleString()}</td>
            </tr>`;
            tbody.innerHTML += row;
        });
    }

    // Hook tab render
    const origRenderCharts = renderChartsForTab;
    renderChartsForTab = function(tabName) {
        if (tabName === 'ccr-soporte') {
            updateDWCCRDashboard();
        } else {
            origRenderCharts(tabName);
        }
    };

    // Initial Load
    updateAllValues();
    updateDWCCRDashboard();
    renderChartsForTab('ccr-soporte');
});

