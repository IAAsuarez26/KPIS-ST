import pyodbc
import json
import os

def export_dw_data():
    conn_str = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=DW_CCR;Trusted_Connection=yes;"
    try:
        conn = pyodbc.connect(conn_str)
    except Exception:
        conn_str = "DRIVER={SQL Server};SERVER=localhost;DATABASE=DW_CCR;Trusted_Connection=yes;"
        conn = pyodbc.connect(conn_str)
    
    cursor = conn.cursor()

    # 1. Total Summary
    cursor.execute("""
        SELECT 
            COUNT(*) AS totalTickets,
            SUM(CASE WHEN E.Estado_Categoria = 'closed' THEN 1 ELSE 0 END) AS ticketsCerrados,
            SUM(CASE WHEN E.Estado_Categoria = 'open' THEN 1 ELSE 0 END) AS ticketsAbiertos,
            SUM(CASE WHEN F.Es_Vencido = 1 THEN 1 ELSE 0 END) AS ticketsVencidos,
            ROUND(AVG(CAST(F.Cumplimiento_SLA AS FLOAT)) * 100, 2) AS pctSLA,
            ROUND(AVG(F.Tiempo_Resolucion_Horas), 2) AS mttrHoras
        FROM fact_ccr.Fact_Atencion_Tickets F
        INNER JOIN dim.Dim_Estado_Ticket E ON F.EstadoTicket_SK = E.EstadoTicket_SK
    """)
    row = cursor.fetchone()
    summary_all = {
        'totalTickets': row[0] or 0,
        'ticketsCerrados': row[1] or 0,
        'ticketsAbiertos': row[2] or 0,
        'ticketsVencidos': row[3] or 0,
        'pctSLA': float(row[4] or 0),
        'mttrHoras': float(row[5] or 0)
    }

    # 2. Monthly Trend Data (by Year & Month)
    cursor.execute("""
        SELECT 
            T.Anio,
            T.Mes,
            T.Nombre_Mes,
            COUNT(*) AS totalTickets,
            SUM(CASE WHEN E.Estado_Categoria = 'closed' THEN 1 ELSE 0 END) AS ticketsCerrados,
            SUM(CASE WHEN F.Es_Vencido = 1 THEN 1 ELSE 0 END) AS ticketsVencidos,
            ROUND(AVG(CAST(F.Cumplimiento_SLA AS FLOAT)) * 100, 2) AS pctSLA,
            ROUND(AVG(F.Tiempo_Resolucion_Horas), 2) AS mttrHoras
        FROM fact_ccr.Fact_Atencion_Tickets F
        INNER JOIN dim.Dim_Tiempo T ON F.Tiempo_Creacion_SK = T.Tiempo_SK
        INNER JOIN dim.Dim_Estado_Ticket E ON F.EstadoTicket_SK = E.EstadoTicket_SK
        GROUP BY T.Anio, T.Mes, T.Nombre_Mes
        ORDER BY T.Anio ASC, T.Mes ASC
    """)
    monthly_data = []
    for r in cursor.fetchall():
        monthly_data.append({
            'year': r[0],
            'monthNum': r[1],
            'monthName': r[2].strip(),
            'totalTickets': r[3],
            'ticketsCerrados': r[4],
            'ticketsVencidos': r[5],
            'pctSLA': float(r[6] or 0),
            'mttrHoras': float(r[7] or 0)
        })

    # 3. Topic / Category Breakdown
    cursor.execute("""
        SELECT 
            TA.Nombre_Tema,
            COUNT(*) AS totalTickets,
            ROUND(AVG(F.Tiempo_Resolucion_Horas), 2) AS mttrHoras
        FROM fact_ccr.Fact_Atencion_Tickets F
        INNER JOIN dim.Dim_Tema_Ayuda TA ON F.TemaAyuda_SK = TA.TemaAyuda_SK
        GROUP BY TA.Nombre_Tema
        ORDER BY totalTickets DESC
    """)
    topics_data = [{'name': r[0].strip(), 'count': r[1], 'mttr': float(r[2] or 0)} for r in cursor.fetchall()]

    # 4. Agent Breakdown
    cursor.execute("""
        SELECT 
            A.Nombre_Completo,
            COUNT(*) AS totalTickets,
            ROUND(AVG(F.Tiempo_Resolucion_Horas), 2) AS mttrHoras,
            SUM(CASE WHEN F.Es_Vencido = 1 THEN 1 ELSE 0 END) AS vencidos
        FROM fact_ccr.Fact_Atencion_Tickets F
        INNER JOIN dim.Dim_Agente_Staff A ON F.Agente_SK = A.Agente_SK
        GROUP BY A.Nombre_Completo
        ORDER BY totalTickets DESC
    """)
    agents_data = [{'name': r[0].strip(), 'count': r[1], 'mttr': float(r[2] or 0), 'vencidos': r[3]} for r in cursor.fetchall()]

    # 5. Audit Log Execution
    cursor.execute("""
        SELECT TOP 10 Log_ID, Nombre_Proceso, Paso, Fecha_Inicio, Fecha_Fin, Estado, Registros_Afectados
        FROM staging.ETL_Log_Ejecucion
        ORDER BY Log_ID DESC
    """)
    audit_log = []
    for r in cursor.fetchall():
        audit_log.append({
            'logId': r[0],
            'proceso': r[1],
            'paso': r[2],
            'inicio': str(r[3]),
            'fin': str(r[4]) if r[4] else '',
            'estado': r[5],
            'registros': r[6] or 0
        })

    conn.close()

    dw_ccr_payload = {
        'summaryAll': summary_all,
        'monthlyTrend': monthly_data,
        'topics': topics_data,
        'agents': agents_data,
        'auditLog': audit_log
    }

    out_file = os.path.join(os.path.dirname(__file__), "dashboard_app", "data_dw_ccr.js")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write("/* GENERATED FROM DW_CCR LIVE DATABASE */\n")
        f.write(f"const DW_CCR_LIVE_DATA = {json.dumps(dw_ccr_payload, indent=2, ensure_ascii=False)};\n")
    
    print(f"Data successfully exported to {out_file}")

if __name__ == "__main__":
    export_dw_data()
