#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===============================================================================
ETL SCRIPT STANDALONE: MYSQL OSTICKET TO SQL SERVER DW_CCR
Origen: MySQL osTicket (Host: 192.168.0.99, Port: 3306, User: root, DB: osticket)
Destino: Microsoft SQL Server (BD: DW_CCR, Esquema: staging)
===============================================================================
"""

import sys
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("ETL_DW_CCR")

# Parámetros de Conexión Origen (MySQL osTicket)
MYSQL_CONFIG = {
    'host': '192.168.0.99',
    'port': 3306,
    'user': 'root',
    'password': 'Paty2101',
    'database': 'osticket',
    'charset': 'utf8mb4'
}

# Parámetros de Conexión Destino (SQL Server DW_CCR)
SQLSERVER_CONFIG = {
    'server': 'localhost',  # Nombre de la instancia SQL Server
    'database': 'DW_CCR',
    'trusted_connection': 'yes',  # 'yes' para Autenticación de Windows, o especifique user/password
    'driver': '{ODBC Driver 17 for SQL Server}'
}

def conectar_mysql():
    try:
        import pymysql
        conn = pymysql.connect(**MYSQL_CONFIG, cursorclass=pymysql.cursors.DictCursor)
        logger.info("Conexión exitosa a MySQL osTicket (192.168.0.99:3306)")
        return conn
    except Exception as e:
        logger.error(f"Error al conectar a MySQL: {e}")
        raise

def conectar_sqlserver():
    try:
        import pyodbc
        conn_str = f"DRIVER={SQLSERVER_CONFIG['driver']};SERVER={SQLSERVER_CONFIG['server']};DATABASE={SQLSERVER_CONFIG['database']};Trusted_Connection={SQLSERVER_CONFIG['trusted_connection']};"
        conn = pyodbc.connect(conn_str, autocommit=True)
        logger.info("Conexión exitosa a SQL Server DW_CCR")
        return conn
    except Exception as e:
        logger.error(f"Error al conectar a SQL Server: {e}")
        raise

def extraer_y_cargar_staging(conn_mysql, conn_sqlserver):
    logger.info("Poblando capa de Staging en SQL Server desde MySQL...")
    cursor_mysql = conn_mysql.cursor()
    cursor_sql = conn_sqlserver.cursor()
    
    try:
        cursor_sql.fast_executemany = True
    except Exception:
        pass

    tablas_etl = [
        {
            "nombre": "Organization",
            "staging_table": "staging.stg_ost_organization",
            "sql_mysql": """
                SELECT 
                    O.id AS ID_Organizacion_Origen,
                    COALESCE(O.name, 'ORGANIZACIÓN SIN NOMBRE') AS Nombre_Organizacion,
                    COALESCE(O.manager, '') AS Gerente_Manager,
                    COALESCE(O.domain, '') AS Dominio,
                    COALESCE(C.phone, '') AS Telefono,
                    COALESCE(C.address, '') AS Direccion,
                    COALESCE(C.website, '') AS Sitio_Web,
                    COALESCE(O.status, 0) AS Estado_Organizacion,
                    O.created AS Fecha_Creacion
                FROM osticket.ost_organization O
                LEFT JOIN osticket.ost_organization__cdata C ON O.id = C.org_id
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_organization VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "User",
            "staging_table": "staging.stg_ost_user",
            "sql_mysql": """
                SELECT 
                    U.id AS ID_Usuario_Origen,
                    COALESCE(U.org_id, 0) AS ID_Organizacion_Origen,
                    COALESCE(U.name, C.name, 'USUARIO GENERAL') AS Nombre_Usuario,
                    COALESCE(E.address, C.email, '') AS Email_Usuario,
                    COALESCE(C.phone, '') AS Telefono,
                    COALESCE(U.status, 0) AS Estado_Usuario,
                    U.created AS Fecha_Creacion_Origen,
                    COALESCE(C.notes, '') AS Notas
                FROM osticket.ost_user U
                LEFT JOIN osticket.ost_user_email E ON U.default_email_id = E.id
                LEFT JOIN osticket.ost_user__cdata C ON U.id = C.user_id
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_user VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Staff",
            "staging_table": "staging.stg_ost_staff",
            "sql_mysql": """
                SELECT 
                    S.staff_id AS ID_Agente_Origen,
                    COALESCE(S.dept_id, 0) AS ID_Departamento_Origen,
                    COALESCE(S.role_id, 0) AS ID_Rol_Origen,
                    S.username AS Username,
                    TRIM(CONCAT(COALESCE(S.firstname, ''), ' ', COALESCE(S.lastname, ''))) AS Nombre_Completo,
                    S.email AS Email,
                    S.phone AS Telefono,
                    S.phone_ext AS Extension,
                    S.mobile AS Movil,
                    S.isactive AS Es_Activo,
                    S.isadmin AS Es_Admin,
                    S.onvacation AS En_Vacaciones,
                    S.created AS Fecha_Creacion
                FROM osticket.ost_staff S
                WHERE S.isactive = 1
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_staff VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Department",
            "staging_table": "staging.stg_ost_department",
            "sql_mysql": """
                SELECT 
                    id AS ID_Departamento_Origen,
                    pid AS ID_Padre_Origen,
                    name AS Nombre_Departamento,
                    ispublic AS Es_Publico,
                    signature AS Firma_Dept,
                    path AS Ruta_Path,
                    created AS Fecha_Creacion
                FROM osticket.ost_department
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_department VALUES (?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Team",
            "staging_table": "staging.stg_ost_team",
            "sql_mysql": """
                SELECT 
                    team_id AS ID_Equipo_Origen,
                    lead_id AS ID_Lider_Origen,
                    name AS Nombre_Equipo,
                    notes AS Notas,
                    created AS Fecha_Creacion
                FROM osticket.ost_team
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_team VALUES (?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Help Topic",
            "staging_table": "staging.stg_ost_help_topic",
            "sql_mysql": """
                SELECT 
                    topic_id AS ID_Topic_Origen,
                    topic_pid AS ID_Topic_Padre_Origen,
                    topic AS Nombre_Tema,
                    isactive AS Es_Activo,
                    ispublic AS Es_Publico,
                    priority_id AS ID_Prioridad_Defecto,
                    dept_id AS ID_Departamento_Defecto,
                    sla_id AS ID_SLA_Defecto,
                    created AS Fecha_Creacion
                FROM osticket.ost_help_topic
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_help_topic VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Ticket Status",
            "staging_table": "staging.stg_ost_ticket_status",
            "sql_mysql": """
                SELECT 
                    id AS ID_Estado_Origen,
                    name AS Nombre_Estado,
                    state AS Estado_Categoria,
                    mode AS Modo,
                    flags AS Flags,
                    sort AS Orden_Sort
                FROM osticket.ost_ticket_status
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_ticket_status VALUES (?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Ticket Priority",
            "staging_table": "staging.stg_ost_ticket_priority",
            "sql_mysql": """
                SELECT 
                    priority_id AS ID_Prioridad_Origen,
                    priority AS Nombre_Prioridad,
                    priority_desc AS Descripcion_Prioridad,
                    priority_color AS Color_Prioridad,
                    priority_urgency AS Nivel_Urgencia,
                    ispublic AS Es_Publica
                FROM osticket.ost_ticket_priority
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_ticket_priority VALUES (?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "SLA",
            "staging_table": "staging.stg_ost_sla",
            "sql_mysql": """
                SELECT 
                    id AS ID_SLA_Origen,
                    name AS Nombre_SLA,
                    grace_period AS Periodo_Gracia_Horas,
                    notes AS Notas,
                    created AS Fecha_Creacion
                FROM osticket.ost_sla
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_sla VALUES (?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Ticket",
            "staging_table": "staging.stg_ost_ticket",
            "sql_mysql": """
                SELECT 
                    T.ticket_id AS ID_Ticket_Origen,
                    COALESCE(T.number, CAST(T.ticket_id AS CHAR)) AS Numero_Ticket,
                    T.created AS Fecha_Hora_Creacion,
                    T.closed AS Fecha_Hora_Cierre,
                    COALESCE(T.duedate, T.est_duedate) AS Fecha_Hora_Vencimiento,
                    T.lastupdate AS Fecha_Hora_Ultima_Actualizacion,
                    COALESCE(T.user_id, 0) AS user_id,
                    COALESCE(T.staff_id, 0) AS staff_id,
                    COALESCE(T.dept_id, 0) AS dept_id,
                    COALESCE(T.team_id, 0) AS team_id,
                    COALESCE(T.topic_id, 0) AS topic_id,
                    COALESCE(T.status_id, 0) AS status_id,
                    COALESCE(T.sla_id, 0) AS sla_id,
                    COALESCE(T.source, 'Otro') AS Canal_Origen,
                    T.source_extra AS Canal_Origen_Extra,
                    COALESCE(T.ip_address, '') AS Direccion_IP,
                    TC.subject AS Asunto_Ticket,
                    TC.priority AS Nombre_Prioridad_Origen,
                    COALESCE(T.isoverdue, 0) AS Es_Vencido,
                    COALESCE(T.isanswered, 0) AS Es_Respondido
                FROM osticket.ost_ticket T
                LEFT JOIN osticket.ost_ticket__cdata TC ON T.ticket_id = TC.ticket_id
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_ticket VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Thread Event",
            "staging_table": "staging.stg_ost_thread_event",
            "sql_mysql": """
                SELECT 
                    E.id AS ID_Evento_Origen,
                    COALESCE(TH.object_id, 0) AS ID_Ticket_Origen,
                    E.timestamp AS Fecha_Hora_Evento,
                    COALESCE(E.staff_id, 0) AS staff_id,
                    COALESCE(E.team_id, 0) AS team_id,
                    COALESCE(E.dept_id, 0) AS dept_id,
                    COALESCE(E.topic_id, 0) AS topic_id,
                    E.state AS Tipo_Evento,
                    COALESCE(E.username, 'SYSTEM') AS Usuario_Ejecutor,
                    COALESCE(E.uid_type, 'S') AS Tipo_Usuario_Ejecutor,
                    E.data AS Datos_Evento,
                    COALESCE(E.annulled, 0) AS Es_Anulado
                FROM osticket.ost_thread_event E
                INNER JOIN osticket.ost_thread TH ON E.thread_id = TH.id AND TH.object_type = 'T'
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_thread_event VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        },
        {
            "nombre": "Thread Entry",
            "staging_table": "staging.stg_ost_thread_entry",
            "sql_mysql": """
                SELECT 
                    TE.id AS ID_Entrada_Origen,
                    COALESCE(TH.object_id, 0) AS ID_Ticket_Origen,
                    TE.created AS Fecha_Hora_Interaccion,
                    COALESCE(TE.staff_id, 0) AS staff_id,
                    COALESCE(TE.user_id, 0) AS user_id,
                    COALESCE(TE.type, '') AS Tipo_Poster,
                    COALESCE(TE.source, '') AS Fuente_Mensaje,
                    COALESCE(TE.format, 'html') AS Formato,
                    TE.title AS Titulo_Mensaje,
                    COALESCE(TE.body, '') AS Cuerpo_Mensaje
                FROM osticket.ost_thread_entry TE
                INNER JOIN osticket.ost_thread TH ON TE.thread_id = TH.id AND TH.object_type = 'T'
            """,
            "insert_sql": "INSERT INTO staging.stg_ost_thread_entry VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        }
    ]

    for item in tablas_etl:
        logger.info(f"Cargando Staging: {item['nombre']}...")
        cursor_mysql.execute(item['sql_mysql'])
        filas = cursor_mysql.fetchall()
        rows = [tuple(r.values()) for r in filas]
        
        cursor_sql.execute(f"TRUNCATE TABLE {item['staging_table']}")
        if rows:
            cursor_sql.executemany(item['insert_sql'], rows)
        logger.info(f"  -> {len(rows)} registros insertados en {item['staging_table']}")

def ejecutar_sp_sqlserver(conn_sqlserver, sp_name):
    try:
        cursor = conn_sqlserver.cursor()
        logger.info(f"Ejecutando procedimiento almacenado: {sp_name}")
        cursor.execute(f"EXEC {sp_name}")
        logger.info(f"Finalizado correctamente: {sp_name}")
    except Exception as e:
        logger.error(f"Error al ejecutar {sp_name}: {e}")
        raise

def main():
    logger.info("===================================================================")
    logger.info("INICIANDO PROCESO ETL MYSQL OSTICKET -> SQL SERVER DW_CCR")
    logger.info("===================================================================")

    # 1. Probar conectividad con ambos motores
    conn_mysql = conectar_mysql()
    conn_sqlserver = conectar_sqlserver()

    # 2. Extraer de MySQL y Cargar Staging en SQL Server
    extraer_y_cargar_staging(conn_mysql, conn_sqlserver)

    conn_mysql.close()

    # 3. Ejecutar la orquestación maestra en SQL Server (Dimensiones y Hechos)
    ejecutar_sp_sqlserver(conn_sqlserver, "fact_ccr.sp_Ejecutar_ETL_Diario_CCR")
    
    conn_sqlserver.close()

    logger.info("===================================================================")
    logger.info("PROCESO ETL FINALIZADO CON ÉXITO.")
    logger.info("===================================================================")

if __name__ == "__main__":
    main()

