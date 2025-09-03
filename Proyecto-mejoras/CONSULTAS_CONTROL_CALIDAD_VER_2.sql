/* =====================================================================================================
PROYECTO: SIGEU – Sistema de Gestión de Eventos Universitarios
MÓDULO: CONSULTAS AD-HOC (REPORTES/KPI)
VERSIÓN: 1.0
FECHA: 2025-09-02 04:01
AUTORES (equipo): David Hernández, Sebastián Manrique, Daniel Brand, Michael Cardona, Andrés Gómez
DESCRIPCIÓN:
  Consultas de uso cotidiano para control de calidad, auditoría y métricas.
  Incluye índices sugeridos para mejorar rendimiento.
REQUISITOS:
  - Esquema 'sigeu' existente con datos.
===================================================================================================== */

USE sigeu;

-- =========================================================
-- CONSULTA A: Conteo general por estado (KPI pipeline)
-- QUÉ HACE: Cuenta los eventos por estado (borrador, en_revision, aprobado, rechazado, publicado).
-- PARA QUÉ: Indicador ejecutivo del flujo; ayuda a medir atascos por etapa.
-- TABLA: evento(estado)
-- RESULTADO: estado | total
SELECT estado, COUNT(*) AS total
FROM evento
GROUP BY estado
ORDER BY total DESC;


-- =========================================================
-- CONSULTA B: Eventos en revisión con unidades y responsables
-- QUÉ HACE: Para cada evento en_revision, lista sus unidades organizadoras y el responsable asignado (o 'SIN RESPONSABLE').
-- PARA QUÉ: Checklist operativo antes de evaluación; asegura la regla “≥1 responsable por unidad”.
-- TABLAS: evento, evento_unidad, unidad_academica, responsable_asignado, usuario
-- JOINS:
--   e.id_evento = eu.id_evento
--   eu.id_unidad = ua.id_unidad
--   eu.id_evento_unidad = r.evento_unidad_id (LEFT)
--   r.usuario_id = ur.id_usuario (LEFT)
-- RESULTADO: id_evento | titulo | unidad | responsable
SELECT e.id_evento, e.titulo, ua.nombre AS unidad,
       COALESCE(ur.nombre, 'SIN RESPONSABLE') AS responsable
FROM evento e
JOIN evento_unidad    eu ON eu.id_evento = e.id_evento
JOIN unidad_academica ua ON ua.id_unidad = eu.id_unidad
LEFT JOIN responsable_asignado r ON r.evento_unidad_id = eu.id_evento_unidad
LEFT JOIN usuario            ur ON ur.id_usuario = r.usuario_id
WHERE e.estado = 'en_revision'
ORDER BY e.id_evento, ua.nombre;


-- =========================================================
-- CONSULTA C: Aprobados sin acta (alerta crítica)
-- QUÉ HACE: Identifica eventos aprobados que no tienen acta registrada (debe existir 0..1 por evento).
-- RESULTADO: id_evento | titulo | fecha_inicio | fecha_fin
SELECT e.id_evento, e.titulo, e.fecha_inicio, e.fecha_fin
FROM evento e
LEFT JOIN acta_comite a ON a.evento_id = e.id_evento
WHERE e.estado = 'aprobado' AND a.id_acta IS NULL;


-- =========================================================
-- CONSULTA D: Eventos con organizaciones externas y certificado
-- QUÉ HACE: Muestra por evento la organización participante, quién asiste (rep. legal o alterno) y el certificado PDF.
-- RESULTADO: id_evento | titulo | organizacion | quien_asiste | url_certificado_pdf
SELECT e.id_evento, e.titulo,
       oe.nombre AS organizacion, 
       CASE WHEN po.participa_rep_legal=1 THEN 'Representante legal'
            ELSE po.representante_participante END AS quien_asiste,
       po.url_certificado_pdf
FROM evento e
JOIN participacion_org    po ON po.evento_id = e.id_evento
JOIN organizacion_externa oe ON oe.id_organizacion = po.organizacion_id
ORDER BY e.id_evento;


-- =========================================================
-- CONSULTA E: Notificaciones de rechazo en últimos 30 días
-- QUÉ HACE: Lista rechazos recientes con su justificación y fecha, para análisis de causas.
-- RESULTADO: id_evento | titulo | fecha_envio | justificacion
SELECT e.id_evento, e.titulo, n.fecha_envio, n.justificacion
FROM notificacion n
JOIN evento e ON e.id_evento = n.evento_id
WHERE n.tipo = 'rechazo'
  AND n.fecha_envio >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
ORDER BY n.fecha_envio DESC;


-- =========================================================
-- CONSULTA F: Usuarios con más de una contraseña vigente (no debería pasar)
-- QUÉ HACE: Audita incumplimientos de la regla (el trigger lo impide, pero verificamos).
-- RESULTADO: id_usuario | vigentes (>1 es anomalía)
SELECT id_usuario, COUNT(*) AS vigentes
FROM historial_contrasena
WHERE vigente = 1
GROUP BY id_usuario
HAVING COUNT(*) > 1;


-- =========================================================
-- CONSULTA G: Eventos sin aval (pendientes de documento)
-- QUÉ HACE: Lista eventos que no tienen aval registrado (requisito del enunciado).
-- RESULTADO: id_evento | titulo | estado
SELECT e.id_evento, e.titulo, e.estado
FROM evento e
LEFT JOIN aval a ON a.evento_id = e.id_evento
WHERE a.id_aval IS NULL
ORDER BY e.id_evento;


-- =========================================================
-- CONSULTA H: Resumen de carga por unidad y estado
-- QUÉ HACE: Cuenta cuántos eventos tiene cada unidad por estado (distribución de carga).
-- RESULTADO: unidad | estado | total
SELECT ua.nombre AS unidad, e.estado, COUNT(*) AS total
FROM unidad_academica ua
JOIN evento_unidad eu ON eu.id_unidad = ua.id_unidad
JOIN evento e         ON e.id_evento = eu.id_evento
GROUP BY ua.nombre, e.estado
ORDER BY ua.nombre, total DESC;


-- =========================================================
-- CONSULTA I: Próximos eventos (siguiente semana)
-- QUÉ HACE: Agenda operativa próxima semana con instalación asignada.
-- RESULTADO: id_evento | titulo | fecha_inicio | instalacion
SELECT e.id_evento, e.titulo, e.fecha_inicio, i.nombre AS instalacion
FROM evento e
JOIN instalacion i ON i.id_instalacion = e.id_instalacion
WHERE e.fecha_inicio BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
ORDER BY e.fecha_inicio;


/* =====================================================================================================
ÍNDICES  (RENDIMIENTO)
- Aplicar tras validar cardinalidades y volumen de datos.
===================================================================================================== */
CREATE INDEX IF NOT EXISTS ix_evento_estado        ON evento(estado);
CREATE INDEX IF NOT EXISTS ix_evento_fechas        ON evento(fecha_inicio, fecha_fin);
CREATE INDEX IF NOT EXISTS ix_eu_evento            ON evento_unidad(id_evento);
CREATE INDEX IF NOT EXISTS ix_eu_unidad            ON evento_unidad(id_unidad);
CREATE INDEX IF NOT EXISTS ix_resp_eu              ON responsable_asignado(evento_unidad_id);
CREATE INDEX IF NOT EXISTS ix_part_org             ON participacion_org(organizacion_id);
CREATE INDEX IF NOT EXISTS ix_part_evento          ON participacion_org(evento_id);
CREATE INDEX IF NOT EXISTS ix_notif_evento         ON notificacion(evento_id);
