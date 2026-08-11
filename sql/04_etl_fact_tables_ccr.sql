-- ===============================================================================
-- ETL PASO 3: CARGA Y SINCRONIZACIÓN DE TABLAS DE HECHOS (OPENQUERY)
-- Base de Datos Destino: DW_CCR (SQL Server)
-- Origen de Datos: osTicket MySQL Database (Script_CCR.sql / MYSQL_OSTICKET)
-- ===============================================================================

USE [DW_CCR];
GO

-- -------------------------------------------------------------------------------
-- 1. Carga de Fact_Atencion_Tickets (Hecho Principal de Tickets)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_ccr.sp_ETL_Fact_Atencion_Tickets', 'P') IS NOT NULL DROP PROCEDURE fact_ccr.sp_ETL_Fact_Atencion_Tickets;
GO
CREATE PROCEDURE fact_ccr.sp_ETL_Fact_Atencion_Tickets
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO fact_ccr.Fact_Atencion_Tickets AS Target
    USING (
        SELECT 
            T.ID_Ticket_Origen,
            T.Numero_Ticket,
            
            -- SKs de Tiempo
            CAST(CONVERT(VARCHAR(8), T.Fecha_Hora_Creacion, 112) AS INT) AS Tiempo_Creacion_SK,
            CASE WHEN T.Fecha_Hora_Cierre IS NOT NULL THEN CAST(CONVERT(VARCHAR(8), T.Fecha_Hora_Cierre, 112) AS INT) ELSE 19000101 END AS Tiempo_Cierre_SK,
            CASE WHEN T.Fecha_Hora_Vencimiento IS NOT NULL THEN CAST(CONVERT(VARCHAR(8), T.Fecha_Hora_Vencimiento, 112) AS INT) ELSE 19000101 END AS Tiempo_Vencimiento_SK,
            CASE WHEN T.Fecha_Hora_Ultima_Actualizacion IS NOT NULL THEN CAST(CONVERT(VARCHAR(8), T.Fecha_Hora_Ultima_Actualizacion, 112) AS INT) ELSE 19000101 END AS Tiempo_Ultima_Actualizacion_SK,

            -- Fechas Reales
            T.Fecha_Hora_Creacion,
            T.Fecha_Hora_Cierre,
            T.Fecha_Hora_Vencimiento,
            T.Fecha_Hora_Ultima_Actualizacion,

            -- Dimensiones Relacionadas (Lookup SK con Fallback a SK = 1)
            COALESCE(DU.Usuario_SK, 1) AS Usuario_SK,
            COALESCE(DO.Organizacion_SK, DU.ID_Organizacion_Origen, 1) AS Organizacion_SK,
            COALESCE(DA.Agente_SK, 1) AS Agente_SK,
            COALESCE(DD.Departamento_SK, 1) AS Departamento_SK,
            COALESCE(DE.Equipo_SK, 1) AS Equipo_SK,
            COALESCE(DTA.TemaAyuda_SK, 1) AS TemaAyuda_SK,
            COALESCE(DET.EstadoTicket_SK, 1) AS EstadoTicket_SK,
            COALESCE(DPT.PrioridadTicket_SK, 1) AS PrioridadTicket_SK,
            COALESCE(DS.SLA_SK, 1) AS SLA_SK,

            -- Atributos Degenerados
            T.Canal_Origen,
            T.Canal_Origen_Extra,
            T.Direccion_IP,
            T.Asunto_Ticket,

            -- Flags
            T.Es_Vencido,
            T.Es_Respondido,
            CASE WHEN T.Fecha_Hora_Cierre IS NOT NULL AND (T.Fecha_Hora_Cierre <= T.Fecha_Hora_Vencimiento OR T.Es_Vencido = 0) THEN 1 ELSE 0 END AS Cumplimiento_SLA,

            -- Métricas
            1 AS Cantidad_Tickets,
            CASE WHEN T.Fecha_Hora_Cierre IS NOT NULL THEN DATEDIFF(minute, T.Fecha_Hora_Creacion, T.Fecha_Hora_Cierre) ELSE NULL END AS Tiempo_Resolucion_Minutos,
            CASE WHEN T.Fecha_Hora_Cierre IS NOT NULL THEN ROUND(DATEDIFF(minute, T.Fecha_Hora_Creacion, T.Fecha_Hora_Cierre) / 60.0, 2) ELSE NULL END AS Tiempo_Resolucion_Horas,
            CASE WHEN T.Fecha_Hora_Vencimiento IS NOT NULL THEN DATEDIFF(day, T.Fecha_Hora_Creacion, T.Fecha_Hora_Vencimiento) ELSE NULL END AS Dias_Hasta_Vencimiento
        FROM staging.stg_ost_ticket T
        LEFT JOIN dim.Dim_Usuario_Cliente DU ON T.user_id = DU.ID_Usuario_Origen
        LEFT JOIN dim.Dim_Organizacion DO ON DU.ID_Organizacion_Origen = DO.ID_Organizacion_Origen
        LEFT JOIN dim.Dim_Agente_Staff DA ON T.staff_id = DA.ID_Agente_Origen
        LEFT JOIN dim.Dim_Departamento DD ON T.dept_id = DD.ID_Departamento_Origen
        LEFT JOIN dim.Dim_Equipo DE ON T.team_id = DE.ID_Equipo_Origen
        LEFT JOIN dim.Dim_Tema_Ayuda DTA ON T.topic_id = DTA.ID_Topic_Origen
        LEFT JOIN dim.Dim_Estado_Ticket DET ON T.status_id = DET.ID_Estado_Origen
        LEFT JOIN dim.Dim_Prioridad_Ticket DPT ON T.Nombre_Prioridad_Origen = DPT.Nombre_Prioridad OR DPT.ID_Prioridad_Origen = 1
        LEFT JOIN dim.Dim_SLA DS ON T.sla_id = DS.ID_SLA_Origen
    ) AS Source
    ON (Target.ID_Ticket_Origen = Source.ID_Ticket_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Numero_Ticket = Source.Numero_Ticket,
            Target.Tiempo_Cierre_SK = Source.Tiempo_Cierre_SK,
            Target.Tiempo_Vencimiento_SK = Source.Tiempo_Vencimiento_SK,
            Target.Tiempo_Ultima_Actualizacion_SK = Source.Tiempo_Ultima_Actualizacion_SK,
            Target.Fecha_Hora_Cierre = Source.Fecha_Hora_Cierre,
            Target.Fecha_Hora_Vencimiento = Source.Fecha_Hora_Vencimiento,
            Target.Fecha_Hora_Ultima_Actualizacion = Source.Fecha_Hora_Ultima_Actualizacion,
            Target.Usuario_SK = Source.Usuario_SK,
            Target.Organizacion_SK = Source.Organizacion_SK,
            Target.Agente_SK = Source.Agente_SK,
            Target.Departamento_SK = Source.Departamento_SK,
            Target.Equipo_SK = Source.Equipo_SK,
            Target.TemaAyuda_SK = Source.TemaAyuda_SK,
            Target.EstadoTicket_SK = Source.EstadoTicket_SK,
            Target.PrioridadTicket_SK = Source.PrioridadTicket_SK,
            Target.SLA_SK = Source.SLA_SK,
            Target.Canal_Origen = Source.Canal_Origen,
            Target.Es_Vencido = Source.Es_Vencido,
            Target.Es_Respondido = Source.Es_Respondido,
            Target.Cumplimiento_SLA = Source.Cumplimiento_SLA,
            Target.Asunto_Ticket = Source.Asunto_Ticket,
            Target.Tiempo_Resolucion_Minutos = Source.Tiempo_Resolucion_Minutos,
            Target.Tiempo_Resolucion_Horas = Source.Tiempo_Resolucion_Horas,
            Target.Dias_Hasta_Vencimiento = Source.Dias_Hasta_Vencimiento
    WHEN NOT MATCHED THEN
        INSERT (
            ID_Ticket_Origen, Numero_Ticket, Tiempo_Creacion_SK, Tiempo_Cierre_SK, Tiempo_Vencimiento_SK, Tiempo_Ultima_Actualizacion_SK,
            Fecha_Hora_Creacion, Fecha_Hora_Cierre, Fecha_Hora_Vencimiento, Fecha_Hora_Ultima_Actualizacion,
            Usuario_SK, Organizacion_SK, Agente_SK, Departamento_SK, Equipo_SK, TemaAyuda_SK, EstadoTicket_SK, PrioridadTicket_SK, SLA_SK,
            Canal_Origen, Canal_Origen_Extra, Direccion_IP, Asunto_Ticket, Es_Vencido, Es_Respondido, Cumplimiento_SLA,
            Cantidad_Tickets, Tiempo_Resolucion_Minutos, Tiempo_Resolucion_Horas, Dias_Hasta_Vencimiento
        )
        VALUES (
            Source.ID_Ticket_Origen, Source.Numero_Ticket, Source.Tiempo_Creacion_SK, Source.Tiempo_Cierre_SK, Source.Tiempo_Vencimiento_SK, Source.Tiempo_Ultima_Actualizacion_SK,
            Source.Fecha_Hora_Creacion, Source.Fecha_Hora_Cierre, Source.Fecha_Hora_Vencimiento, Source.Fecha_Hora_Ultima_Actualizacion,
            Source.Usuario_SK, Source.Organizacion_SK, Source.Agente_SK, Source.Departamento_SK, Source.Equipo_SK, Source.TemaAyuda_SK, Source.EstadoTicket_SK, Source.PrioridadTicket_SK, Source.SLA_SK,
            Source.Canal_Origen, Source.Canal_Origen_Extra, Source.Direccion_IP, Source.Asunto_Ticket, Source.Es_Vencido, Source.Es_Respondido, Source.Cumplimiento_SLA,
            Source.Cantidad_Tickets, Source.Tiempo_Resolucion_Minutos, Source.Tiempo_Resolucion_Horas, Source.Dias_Hasta_Vencimiento
        );
END;
GO

-- -------------------------------------------------------------------------------
-- 2. Carga de Fact_Eventos_Trazabilidad (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_ccr.sp_ETL_Fact_Eventos_Trazabilidad', 'P') IS NOT NULL DROP PROCEDURE fact_ccr.sp_ETL_Fact_Eventos_Trazabilidad;
GO
CREATE PROCEDURE fact_ccr.sp_ETL_Fact_Eventos_Trazabilidad
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO fact_ccr.Fact_Eventos_Trazabilidad AS Target
    USING (
        SELECT 
            E.ID_Evento_Origen,
            FT.Ticket_SK,
            CAST(CONVERT(VARCHAR(8), E.Fecha_Hora_Evento, 112) AS INT) AS Tiempo_Evento_SK,
            E.Fecha_Hora_Evento,
            COALESCE(DA.Agente_SK, 1) AS Agente_SK,
            COALESCE(DE.Equipo_SK, 1) AS Equipo_SK,
            COALESCE(DD.Departamento_SK, 1) AS Departamento_SK,
            COALESCE(DTA.TemaAyuda_SK, 1) AS TemaAyuda_SK,
            E.Tipo_Evento,
            E.Usuario_Ejecutor,
            E.Tipo_Usuario_Ejecutor,
            E.Datos_Evento,
            E.Es_Anulado,
            1 AS Cantidad_Eventos
        FROM staging.stg_ost_thread_event E
        INNER JOIN fact_ccr.Fact_Atencion_Tickets FT ON E.ID_Ticket_Origen = FT.ID_Ticket_Origen
        LEFT JOIN dim.Dim_Agente_Staff DA ON E.staff_id = DA.ID_Agente_Origen
        LEFT JOIN dim.Dim_Equipo DE ON E.team_id = DE.ID_Equipo_Origen
        LEFT JOIN dim.Dim_Departamento DD ON E.dept_id = DD.ID_Departamento_Origen
        LEFT JOIN dim.Dim_Tema_Ayuda DTA ON E.topic_id = DTA.ID_Topic_Origen
    ) AS Source
    ON (Target.ID_Evento_Origen = Source.ID_Evento_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Tipo_Evento = Source.Tipo_Evento,
            Target.Usuario_Ejecutor = Source.Usuario_Ejecutor,
            Target.Datos_Evento = Source.Datos_Evento,
            Target.Es_Anulado = Source.Es_Anulado
    WHEN NOT MATCHED THEN
        INSERT (ID_Evento_Origen, Ticket_SK, Tiempo_Evento_SK, Fecha_Hora_Evento, Agente_SK, Equipo_SK, Departamento_SK, TemaAyuda_SK, Tipo_Evento, Usuario_Ejecutor, Tipo_Usuario_Ejecutor, Datos_Evento, Es_Anulado, Cantidad_Eventos)
        VALUES (Source.ID_Evento_Origen, Source.Ticket_SK, Source.Tiempo_Evento_SK, Source.Fecha_Hora_Evento, Source.Agente_SK, Source.Equipo_SK, Source.Departamento_SK, Source.TemaAyuda_SK, Source.Tipo_Evento, Source.Usuario_Ejecutor, Source.Tipo_Usuario_Ejecutor, Source.Datos_Evento, Source.Es_Anulado, Source.Cantidad_Eventos);
END;
GO

-- -------------------------------------------------------------------------------
-- 3. Carga de Fact_Interacciones_Conversaciones (Staging)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('fact_ccr.sp_ETL_Fact_Interacciones_Conversaciones', 'P') IS NOT NULL DROP PROCEDURE fact_ccr.sp_ETL_Fact_Interacciones_Conversaciones;
GO
CREATE PROCEDURE fact_ccr.sp_ETL_Fact_Interacciones_Conversaciones
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO fact_ccr.Fact_Interacciones_Conversaciones AS Target
    USING (
        SELECT 
            TE.ID_Entrada_Origen,
            FT.Ticket_SK,
            CAST(CONVERT(VARCHAR(8), TE.Fecha_Hora_Interaccion, 112) AS INT) AS Tiempo_Interaccion_SK,
            TE.Fecha_Hora_Interaccion,
            COALESCE(DA.Agente_SK, 1) AS Agente_SK,
            COALESCE(DU.Usuario_SK, 1) AS Usuario_SK,
            TE.Tipo_Poster,
            TE.Fuente_Mensaje,
            TE.Formato,
            TE.Titulo_Mensaje,
            TE.Cuerpo_Mensaje,
            LEN(TE.Cuerpo_Mensaje) AS Longitud_Caracteres,
            CASE WHEN TE.staff_id > 0 THEN 1 ELSE 0 END AS Es_Respuesta_Agente,
            CASE WHEN TE.user_id > 0 THEN 1 ELSE 0 END AS Es_Mensaje_Cliente,
            1 AS Cantidad_Interacciones
        FROM staging.stg_ost_thread_entry TE
        INNER JOIN fact_ccr.Fact_Atencion_Tickets FT ON TE.ID_Ticket_Origen = FT.ID_Ticket_Origen
        LEFT JOIN dim.Dim_Agente_Staff DA ON TE.staff_id = DA.ID_Agente_Origen
        LEFT JOIN dim.Dim_Usuario_Cliente DU ON TE.user_id = DU.ID_Usuario_Origen
    ) AS Source
    ON (Target.ID_Entrada_Origen = Source.ID_Entrada_Origen)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Titulo_Mensaje = Source.Titulo_Mensaje,
            Target.Cuerpo_Mensaje = Source.Cuerpo_Mensaje,
            Target.Longitud_Caracteres = Source.Longitud_Caracteres
    WHEN NOT MATCHED THEN
        INSERT (ID_Entrada_Origen, Ticket_SK, Tiempo_Interaccion_SK, Fecha_Hora_Interaccion, Agente_SK, Usuario_SK, Tipo_Poster, Fuente_Mensaje, Formato, Titulo_Mensaje, Cuerpo_Mensaje, Longitud_Caracteres, Es_Respuesta_Agente, Es_Mensaje_Cliente, Cantidad_Interacciones)
        VALUES (Source.ID_Entrada_Origen, Source.Ticket_SK, Source.Tiempo_Interaccion_SK, Source.Fecha_Hora_Interaccion, Source.Agente_SK, Source.Usuario_SK, Source.Tipo_Poster, Source.Fuente_Mensaje, Source.Formato, Source.Titulo_Mensaje, Source.Cuerpo_Mensaje, Source.Longitud_Caracteres, Source.Es_Respuesta_Agente, Source.Es_Mensaje_Cliente, Source.Cantidad_Interacciones);
END;
GO

PRINT 'Procedimientos ETL para la Carga de Tablas de Hechos (Staging Layer) creados exitosamente.';
GO

