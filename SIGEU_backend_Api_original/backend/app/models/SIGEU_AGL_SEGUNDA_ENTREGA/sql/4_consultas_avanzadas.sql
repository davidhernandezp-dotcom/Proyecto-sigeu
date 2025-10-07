-- 4_consultas_avanzadas.sql
USE uao_eventos;

-- =========================================================
-- Consulta 01: Productividad por organizador
-- ¿Qué es?: KPI de cuántos eventos ha creado cada organizador.
-- ¿Para qué sirve?: Identificar productividad y concentraciones de carga.
-- Propósito: Rankear organizadores para asignar reconocimientos o balancear trabajo.
-- Información que arroja: idUsuario, nombre, total de eventos creados.
-- Decisiones: Capacitación, incentivos o redistribución de responsabilidades.
-- Tablas y relaciones: evento e  JOIN usuario u (e.idOrganizador = u.idUsuario)
-- =========================================================
SELECT u.idUsuario, u.nombre, COUNT(*) AS eventos_creados
FROM evento e
JOIN usuario u ON u.idUsuario = e.idOrganizador
GROUP BY u.idUsuario, u.nombre
ORDER BY eventos_creados DESC;


-- =========================================================
-- Consulta 02: Horas reservadas por instalación (últimos 30 días, usando instalación por defecto + adicionales)
-- ¿Qué es?: Suma de horas agendadas por espacio.
-- ¿Para qué sirve?: Medir utilización real y detectar saturación.
-- Propósito: Priorización de mantenimiento/expansión y política de reservas.
-- Información que arroja: idInstalacion, nombre, horas_reservadas_30d.
-- Decisiones: Reasignar eventos, ampliar capacidad o abrir nuevos espacios.
-- Tablas y relaciones: evento, eventoInstalacion, instalacion. Se unifican instalaciones
--                      por defecto (evento.idInstalacion) y adicionales (eventoInstalacion).
-- Requiere MySQL 8+ por CTE.
-- =========================================================
WITH ev_inst AS (
  SELECT idEvento, idInstalacion FROM evento
  UNION
  SELECT idEvento, idInstalacion FROM eventoInstalacion
)
SELECT i.idInstalacion, i.nombre,
       SUM(TIMESTAMPDIFF(HOUR, e.fechaInicio, e.fechaFin)) AS horas_reservadas_30d
FROM ev_inst ei
JOIN instalacion i ON i.idInstalacion = ei.idInstalacion
JOIN evento e ON e.idEvento = ei.idEvento
WHERE e.fechaInicio >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY i.idInstalacion, i.nombre
ORDER BY horas_reservadas_30d DESC;


-- =========================================================
-- Consulta 03: Tasa de aprobación global y backlog
-- ¿Qué es?: Métrica de funnel del flujo (registrado→revisión→aprobado/rechazado).
-- ¿Para qué sirve?: Controlar eficiencia del proceso de evaluación.
-- Propósito: Tener tasa de aprobación y pendientes para dimensionar comité.
-- Información que arroja: aprobados, evaluados, tasa_aprobacion_pct, pendientes.
-- Decisiones: Aumentar revisores, ajustar criterios o tiempos SLA.
-- Tablas y relaciones: evento (solo)
-- =========================================================
SELECT
  SUM(estado='aprobado')                                   AS aprobados,
  SUM(estado IN ('aprobado','rechazado'))                  AS evaluados,
  ROUND(100*SUM(estado='aprobado')/
       NULLIF(SUM(estado IN ('aprobado','rechazado')),0),2) AS tasa_aprobacion_pct,
  SUM(estado IN ('registrado','enRevision'))               AS pendientes
FROM evento;


-- =========================================================
-- Consulta 04: Tiempo promedio a decisión (horas) por estado
-- ¿Qué es?: Lead time desde que se registró el evento hasta la decisión.
-- ¿Para qué sirve?: Evaluar desempeño del comité y cumplimiento de SLA.
-- Propósito: Calcular horas promedio a 'aprobado' y 'rechazado'.
-- Información que arroja: estado, horas_promedio.
-- Decisiones: Optimizar agenda del comité o automatizar etapas.
-- Tablas y relaciones: evento e JOIN evaluacion ev (ev.idEvento=e.idEvento)
-- =========================================================
SELECT ev.estado,
       AVG(TIMESTAMPDIFF(HOUR, e.fechaRegistro, ev.fechaRevision)) AS horas_promedio
FROM evaluacion ev
JOIN evento e ON e.idEvento = ev.idEvento
GROUP BY ev.estado;


-- =========================================================
-- Consulta 05: Tasa de aprobación por organizador
-- ¿Qué es?: KPI de calidad por responsable.
-- ¿Para qué sirve?: Ver quiénes presentan propuestas más viables.
-- Propósito: Identificar buenas prácticas o necesidades de acompañamiento.
-- Información que arroja: idUsuario, nombre, aprobados, evaluados, tasa_aprobacion_pct.
-- Decisiones: Mentorías, plantillas de calidad, ajustes de guía.
-- Tablas y relaciones: evento e JOIN usuario u JOIN evaluacion ev
-- =========================================================
SELECT u.idUsuario, u.nombre,
       SUM(ev.estado='aprobado') AS aprobados,
       COUNT(ev.idEvaluacion)    AS evaluados,
       ROUND(100*SUM(ev.estado='aprobado')/NULLIF(COUNT(ev.idEvaluacion),0),2) AS tasa_aprobacion_pct
FROM evento e
JOIN usuario u   ON u.idUsuario = e.idOrganizador
JOIN evaluacion ev ON ev.idEvento = e.idEvento
GROUP BY u.idUsuario, u.nombre
ORDER BY tasa_aprobacion_pct DESC, evaluados DESC;


-- =========================================================
-- Consulta 06: Tasa de aprobación por categoría
-- ¿Qué es?: Comparación de outcomes entre 'académico' y 'lúdico'.
-- ¿Para qué sirve?: Balancear portafolio de eventos.
-- Propósito: Ver qué categoría aporta más aprobaciones.
-- Información que arroja: categoria, aprobados, evaluados, tasa_aprobacion_pct.
-- Decisiones: Reasignar presupuesto, campañas de mejora.
-- Tablas y relaciones: evento e JOIN evaluacion ev
-- =========================================================
SELECT e.categoria,
       SUM(ev.estado='aprobado') AS aprobados,
       COUNT(*)                  AS evaluados,
       ROUND(100*SUM(ev.estado='aprobado')/NULLIF(COUNT(*),0),2) AS tasa_aprobacion_pct
FROM evaluacion ev
JOIN evento e ON e.idEvento = ev.idEvento
GROUP BY e.categoria
ORDER BY tasa_aprobacion_pct DESC;


-- =========================================================
-- Consulta 07: Backlog por antigüedad (SLA) para revisión
-- ¿Qué es?: Envejecimiento de solicitudes sin decisión.
-- ¿Para qué sirve?: Identificar cuellos de botella.
-- Propósito: Agrupar pendientes por rangos de días desde su registro.
-- Información que arroja: buckets 0-2, 3-7, 8-14, >14 días.
-- Decisiones: Aumentar capacidad temporal o cambiar priorización.
-- Tablas y relaciones: evento (solo)
-- =========================================================
SELECT
  SUM(DATEDIFF(CURRENT_DATE(), fechaRegistro) BETWEEN 0 AND 2
      AND estado IN ('registrado','enRevision')) AS pendientes_0a2d,
  SUM(DATEDIFF(CURRENT_DATE(), fechaRegistro) BETWEEN 3 AND 7
      AND estado IN ('registrado','enRevision')) AS pendientes_3a7d,
  SUM(DATEDIFF(CURRENT_DATE(), fechaRegistro) BETWEEN 8 AND 14
      AND estado IN ('registrado','enRevision')) AS pendientes_8a14d,
  SUM(DATEDIFF(CURRENT_DATE(), fechaRegistro) > 14
      AND estado IN ('registrado','enRevision')) AS pendientes_mas14d
FROM evento;


-- =========================================================
-- Consulta 08: Solapamientos por instalación (conteo de conflictos)
-- ¿Qué es?: Número de pares de eventos que chocan en el mismo espacio.
-- ¿Para qué sirve?: Detectar riesgo operativo y necesidad de reprogramación.
-- Propósito: Ordenar instalaciones por cantidad de conflictos.
-- Información que arroja: idInstalacion, nombre, conflictos.
-- Decisiones: Bloqueos de agenda, límites de reservación, reglas.
-- Tablas y relaciones: evento, eventoInstalacion, instalacion. Usa CTE ev_inst.
-- =========================================================
WITH ev_inst AS (
  SELECT idEvento, idInstalacion FROM evento
  UNION
  SELECT idEvento, idInstalacion FROM eventoInstalacion
)
SELECT i.idInstalacion, i.nombre,
       COUNT(*) AS conflictos
FROM ev_inst a
JOIN evento e1 ON e1.idEvento = a.idEvento
JOIN ev_inst b ON a.idInstalacion = b.idInstalacion AND a.idEvento < b.idEvento
JOIN evento e2 ON e2.idEvento = b.idEvento
JOIN instalacion i ON i.idInstalacion = a.idInstalacion
WHERE e1.fechaInicio < e2.fechaFin AND e2.fechaInicio < e1.fechaFin
GROUP BY i.idInstalacion, i.nombre
ORDER BY conflictos DESC;


-- =========================================================
-- Consulta 09: Eventos próximos (7 días) con riesgo de conflicto
-- ¿Qué es?: Lista de eventos que ya tienen traslape agendado.
-- ¿Para qué sirve?: Actuar preventivamente en la semana.
-- Propósito: Notificar organizadores y reubicar a tiempo.
-- Información que arroja: idEvento, nombre, fechaInicio, conflictos_en_instalacion.
-- Decisiones: Cambiar sala/horario, priorizar soporte.
-- Tablas y relaciones: ev_inst, evento, instalacion
-- =========================================================
WITH ev_inst AS (
  SELECT idEvento, idInstalacion FROM evento
  UNION
  SELECT idEvento, idInstalacion FROM eventoInstalacion
)
SELECT e1.idEvento, e1.nombre, e1.fechaInicio, i.nombre AS instalacion,
       COUNT(*) AS conflictos_en_instalacion
FROM ev_inst a
JOIN evento e1 ON e1.idEvento = a.idEvento
JOIN ev_inst b ON a.idInstalacion = b.idInstalacion AND a.idEvento <> b.idEvento
JOIN evento e2 ON e2.idEvento = b.idEvento
JOIN instalacion i ON i.idInstalacion = a.idInstalacion
WHERE e1.fechaInicio BETWEEN CURRENT_DATE() AND DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY)
  AND e1.fechaInicio < e2.fechaFin AND e2.fechaInicio < e1.fechaFin
GROUP BY e1.idEvento, e1.nombre, e1.fechaInicio, i.nombre
ORDER BY e1.fechaInicio ASC, conflictos_en_instalacion DESC;


-- =========================================================
-- Consulta 10: Duración promedio por categoría (minutos)
-- ¿Qué es?: Métrica de esfuerzo estándar por tipo de evento.
-- ¿Para qué sirve?: Plan de horarios y logística.
-- Propósito: Calcular promedio de minutos por categoría.
-- Información que arroja: categoria, duracion_promedio_min.
-- Decisiones: Ajustar slots de agenda y tiempos de limpieza.
-- Tablas y relaciones: evento (solo)
-- =========================================================
SELECT categoria, AVG(TIMESTAMPDIFF(MINUTE, fechaInicio, fechaFin)) AS duracion_promedio_min
FROM evento
GROUP BY categoria;


-- =========================================================
-- Consulta 11: Organizadores con más de 3 eventos activos (fechas futuras)
-- ¿Qué es?: Carga futura por responsable.
-- ¿Para qué sirve?: Balancear acompañamiento operativo.
-- Propósito: Detectar sobrecarga próxima.
-- Información que arroja: idUsuario, nombre, eventos_activos.
-- Decisiones: Asignar co-organizadores o reprogramar.
-- Tablas y relaciones: evento e JOIN usuario u
-- =========================================================
SELECT u.idUsuario, u.nombre, COUNT(*) AS eventos_activos
FROM evento e
JOIN usuario u ON u.idUsuario = e.idOrganizador
WHERE e.fechaFin >= NOW()
GROUP BY u.idUsuario, u.nombre
HAVING COUNT(*) > 3
ORDER BY eventos_activos DESC;


-- =========================================================
-- Consulta 12: Eventos por mes y categoría (últimos 12 meses)
-- ¿Qué es?: Tendencia temporal del portafolio.
-- ¿Para qué sirve?: Planeación anual y presupuestal.
-- Propósito: Series mensuales por categoría.
-- Información que arroja: año, mes, categoria, total_eventos.
-- Decisiones: Calendario maestro, marketing estacional.
-- Tablas y relaciones: evento (solo)
-- =========================================================
SELECT YEAR(fechaInicio) AS anio, LPAD(MONTH(fechaInicio),2,'0') AS mes,
       categoria, COUNT(*) AS total_eventos
FROM evento
WHERE fechaInicio >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(fechaInicio), MONTH(fechaInicio), categoria
ORDER BY anio, mes, categoria;


-- =========================================================
-- Consulta 13: Notificaciones por tipo y receptor (últimos 30 días)
-- ¿Qué es?: Actividad de comunicación a usuarios.
-- ¿Para qué sirve?: Ver carga de mensajes y trazabilidad.
-- Propósito: Contar notificaciones por usuario y tipo.
-- Información que arroja: usuarioReceptor, tipoNotificacion, total.
-- Decisiones: Ajustar plantillas o frecuencia de notificación.
-- Tablas y relaciones: notificacion n JOIN usuario u JOIN evaluacion ev
-- =========================================================
SELECT u.idUsuario, u.nombre, n.tipoNotificacion, COUNT(*) AS total
FROM notificacion n
JOIN usuario u ON u.idUsuario = n.usuarioReceptor
JOIN evaluacion ev ON ev.idEvaluacion = n.idEvaluacion
WHERE n.fechaEnvio >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY u.idUsuario, u.nombre, n.tipoNotificacion
ORDER BY total DESC;


-- =========================================================
-- Consulta 14: Calidad de datos: eventos sin exactamente un organizador principal
-- ¿Qué es?: Validación de regla de negocio.
-- ¿Para qué sirve?: Detectar inconsistencias antes de evaluación.
-- Propósito: Encontrar eventos con 0 o más de 1 principal='S'.
-- Información que arroja: idEvento, principales (conteo).
-- Decisiones: Corregir usuarioEvento o crear trigger adicional.
-- Tablas y relaciones: evento e LEFT JOIN usuarioEvento ue
-- =========================================================
SELECT e.idEvento,
       SUM(ue.principal='S') AS principales
FROM evento e
LEFT JOIN usuarioEvento ue ON ue.idEvento = e.idEvento
GROUP BY e.idEvento
HAVING principales <> 1 OR principales IS NULL;


-- =========================================================
-- Consulta 15: Pendientes vencidos (fechaFin pasada sin decisión final)
-- ¿Qué es?: Control de eventos expirados aún en 'registrado'/'enRevision'.
-- ¿Para qué sirve?: Evitar que se ejecuten sin aval o queden sin cierre.
-- Propósito: Listar casos y priorizar cierre.
-- Información que arroja: idEvento, nombre, estado, fechaFin, dias_atraso.
-- Decisiones: Cerrar, rechazar o reprogramar de manera urgente.
-- Tablas y relaciones: evento (solo)
-- =========================================================
SELECT idEvento, nombre, estado, fechaFin,
       DATEDIFF(CURRENT_DATE(), fechaFin) AS dias_atraso
FROM evento
WHERE estado IN ('registrado','enRevision')
  AND fechaFin < CURRENT_DATE()
ORDER BY dias_atraso DESC;


-- =========================================================
-- Consulta 16: Alianzas externas por categoría (top organizaciones)
-- ¿Qué es?: Participación de terceros por tipo de evento.
-- ¿Para qué sirve?: Gestionar convenios y patrocinios.
-- Propósito: Contar eventos por organización y categoría, top 10.
-- Información que arroja: organizacion, categoria, total_eventos.
-- Decisiones: Renovar/crear alianzas según impacto.
-- Tablas y relaciones: eventoOrganizacion eo JOIN organizacion o JOIN evento e
-- =========================================================
SELECT o.nombre AS organizacion, e.categoria, COUNT(*) AS total_eventos
FROM eventoOrganizacion eo
JOIN organizacion o ON o.idOrganizacion = eo.idOrganizacion
JOIN evento e ON e.idEvento = eo.idEvento
GROUP BY o.nombre, e.categoria
ORDER BY total_eventos DESC
LIMIT 10;
