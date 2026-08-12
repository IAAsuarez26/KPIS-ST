/* ===============================================================================
   KPI's S&T - PORTAL ANALÍTICO DW_CCR (APPLICATION LOGIC & CHART ENGINE)
   =============================================================================== */

document.addEventListener('DOMContentLoaded', () => {
    // State Management
    let currentTheme = 'dark';
    let isSidebarCollapsed = false;
    let currentTab = 'ccr-soporte';
    let ccrYear = 'all';
    let ccrMonth = 'all';
    let ccrCompare = 'none';
    const chartInstances = {};

    // Tab Titles & Subtitles Map
    const tabTitlesMap = {
        'ccr-soporte': { 
            title: 'Atención & KPIs DW_CCR', 
            subtitle: 'Monitoreo Interactivo de Métricas, SLAs y Comparativa YoY / MoM' 
        },
        'ccr-agentes': { 
            title: 'Productividad por Agente Staff', 
            subtitle: 'Matriz de Carga de Trabajo, Tickets Atendidos y Tiempos de Respuesta' 
        },
        'ccr-categorias': { 
            title: 'Demanda por Categorías & Sistema GP', 
            subtitle: 'Clasificación de Requerimientos por Software de Negocio e Incidentes' 
        },
        'ccr-gobernanza': { 
            title: 'Gobernanza TI & Auditoría ETL', 
            subtitle: 'Control de Ejecución de Tuberías de Datos y Registro de Cargas en SQL Server' 
        }
    };

    // DOM Elements Declaration
    const tabButtons = document.querySelectorAll('.nav-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    const tabTitle = document.getElementById('tab-title');
    const tabSubtitle = document.getElementById('tab-subtitle');
    const btnSidebarToggle = document.getElementById('btn-sidebar-toggle');
    const appLayout = document.getElementById('app-layout');
    const sidebarToggleIcon = document.getElementById('sidebar-toggle-icon');
    const btnThemeToggle = document.getElementById('btn-theme-toggle');
    const themeIcon = document.getElementById('theme-icon');
    const btnRefresh = document.getElementById('btn-refresh');

    const filterYearSelect = document.getElementById('filter-year');
    const filterMonthSelect = document.getElementById('filter-month');
    const filterCompareSelect = document.getElementById('filter-compare');

    // ---------------------------------------------------------------------------
    // 1. NAVIGATION TAB HANDLER
    // ---------------------------------------------------------------------------
    tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const targetTab = btn.getAttribute('data-tab');
            if (!targetTab) return;

            tabButtons.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            btn.classList.add('active');
            const targetContent = document.getElementById(`tab-${targetTab}`);
            if (targetContent) targetContent.classList.add('active');

            currentTab = targetTab;
            if (tabTitlesMap[currentTab]) {
                if (tabTitle) tabTitle.textContent = tabTitlesMap[currentTab].title;
                if (tabSubtitle) tabSubtitle.textContent = tabTitlesMap[currentTab].subtitle;
            }

            updateDWCCRDashboard();
        });
    });

    // ---------------------------------------------------------------------------
    // 2. SIDEBAR TOGGLE HANDLER
    // ---------------------------------------------------------------------------
    if (btnSidebarToggle) {
        btnSidebarToggle.addEventListener('click', () => {
            isSidebarCollapsed = !isSidebarCollapsed;
            if (appLayout) {
                if (isSidebarCollapsed) {
                    appLayout.classList.add('sidebar-collapsed');
                    if (sidebarToggleIcon) sidebarToggleIcon.setAttribute('data-lucide', 'panel-left-open');
                } else {
                    appLayout.classList.remove('sidebar-collapsed');
                    if (sidebarToggleIcon) sidebarToggleIcon.setAttribute('data-lucide', 'panel-left-close');
                }
            }
            if (window.lucide) window.lucide.createIcons();

            setTimeout(() => {
                window.dispatchEvent(new Event('resize'));
            }, 300);
        });
    }

    // ---------------------------------------------------------------------------
    // 3. THEME TOGGLE HANDLER
    // ---------------------------------------------------------------------------
    if (btnThemeToggle) {
        btnThemeToggle.addEventListener('click', () => {
            if (currentTheme === 'dark') {
                currentTheme = 'light';
                document.body.classList.remove('dark-theme');
                document.body.classList.add('light-theme');
                if (themeIcon) themeIcon.setAttribute('data-lucide', 'moon');
            } else {
                currentTheme = 'dark';
                document.body.classList.remove('light-theme');
                document.body.classList.add('dark-theme');
                if (themeIcon) themeIcon.setAttribute('data-lucide', 'sun');
            }
            if (window.lucide) window.lucide.createIcons();
            
            Chart.defaults.color = currentTheme === 'dark' ? '#9CA3AF' : '#475569';
            updateDWCCRDashboard();
        });
    }

    // ---------------------------------------------------------------------------
    // 4. FILTER LISTENERS & REFRESH
    // ---------------------------------------------------------------------------
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
    if (btnRefresh) {
        btnRefresh.addEventListener('click', () => {
            updateDWCCRDashboard();
        });
    }

    // ---------------------------------------------------------------------------
    // 5. CHART HELPER: DESTROY PREVIOUS CHARTS
    // ---------------------------------------------------------------------------
    function destroyChart(key) {
        if (chartInstances[key]) {
            chartInstances[key].destroy();
            delete chartInstances[key];
        }
    }

    // Chart Defaults
    Chart.defaults.color = '#9CA3AF';
    Chart.defaults.font.family = "'Inter', sans-serif";

    // ---------------------------------------------------------------------------
    // 6. MAIN ENGINE: UPDATE DW_CCR DASHBOARD (METRICS, CHARTS & TABLES)
    // ---------------------------------------------------------------------------
    function updateDWCCRDashboard() {
        if (typeof DW_CCR_LIVE_DATA === 'undefined') return;

        const allTrend = DW_CCR_LIVE_DATA.monthlyTrend || [];

        // Filter Trend Data
        let filteredTrend = allTrend.filter(item => {
            let matchYear = (ccrYear === 'all') || (item.year == ccrYear);
            let matchMonth = (ccrMonth === 'all') || (item.monthNum == ccrMonth);
            return matchYear && matchMonth;
        });

        if (filteredTrend.length === 0) filteredTrend = allTrend;

        // Calculate KPI values
        let totalTickets = filteredTrend.reduce((sum, i) => sum + i.totalTickets, 0);
        let ticketsCerrados = filteredTrend.reduce((sum, i) => sum + i.ticketsCerrados, 0);
        let ticketsAbiertos = (ccrYear === 'all' && ccrMonth === 'all') ? DW_CCR_LIVE_DATA.summaryAll.ticketsAbiertos : (totalTickets - ticketsCerrados);
        if (ticketsAbiertos < 0) ticketsAbiertos = 0;
        
        let avgSLA = filteredTrend.length > 0 ? (filteredTrend.reduce((sum, i) => sum + i.pctSLA, 0) / filteredTrend.length) : DW_CCR_LIVE_DATA.summaryAll.pctSLA;
        let avgMTTR = filteredTrend.length > 0 ? (filteredTrend.reduce((sum, i) => sum + i.mttrHoras, 0) / filteredTrend.length) : DW_CCR_LIVE_DATA.summaryAll.mttrHoras;
        let closureRate = totalTickets > 0 ? (ticketsCerrados / totalTickets) * 100 : 99.2;

        // Comparison Calculations (YoY / MoM)
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
            compLabelText = `Filtro Activo: ${ccrYear === 'all' ? 'Histórico Completo (2017 - 2026)' : 'Año ' + ccrYear} ${ccrMonth === 'all' ? '' : '/ Mes ' + ccrMonth}`;
        }

        let compTickets = compTrend.reduce((sum, i) => sum + i.totalTickets, 0);
        let compSLA = compTrend.length > 0 ? (compTrend.reduce((sum, i) => sum + i.pctSLA, 0) / compTrend.length) : avgSLA;
        let compMTTR = compTrend.length > 0 ? (compTrend.reduce((sum, i) => sum + i.mttrHoras, 0) / compTrend.length) : avgMTTR;

        let totalDiffPct = compTickets > 0 ? (((totalTickets - compTickets) / compTickets) * 100) : 0;
        let slaDiffPts = avgSLA - compSLA;
        let mttrDiffPct = compMTTR > 0 ? (((avgMTTR - compMTTR) / compMTTR) * 100) : 0;

        // Update Banner & KPI Cards
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

        // Update Badges
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

        // Render Charts for Tab 1
        renderCCRTrendChart(filteredTrend, compTrend);
        renderCCRTopicsChart(DW_CCR_LIVE_DATA.topics || []);
        renderCCRAgentsChart(DW_CCR_LIVE_DATA.agents || []);
        renderCCRStatusChart();

        // Render Tables for Tab 2, 3, 4
        renderCCRTopicsTable(DW_CCR_LIVE_DATA.topics || [], totalTickets);
        renderCCRAgentsTable(DW_CCR_LIVE_DATA.agents || [], totalTickets);
        renderCCRAuditTable(DW_CCR_LIVE_DATA.auditLog || []);

        if (window.lucide) window.lucide.createIcons();
    }

    // ---------------------------------------------------------------------------
    // 7. CHART RENDERING FUNCTIONS
    // ---------------------------------------------------------------------------
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

    // ---------------------------------------------------------------------------
    // 8. TABLE RENDERING FUNCTIONS (Targeting both full and short table IDs)
    // ---------------------------------------------------------------------------
    function renderCCRTopicsTable(topicsData, totalTickets) {
        const tbody = document.querySelector('#table-ccr-topics-full tbody') || document.querySelector('#table-ccr-topics tbody');
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
        const tbody = document.querySelector('#table-ccr-agents-full tbody') || document.querySelector('#table-ccr-agents tbody');
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
        const tbody = document.querySelector('#table-ccr-audit-full tbody') || document.querySelector('#table-ccr-audit tbody');
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

    // ---------------------------------------------------------------------------
    // 9. INITIAL LOAD
    // ---------------------------------------------------------------------------
    updateDWCCRDashboard();
});
