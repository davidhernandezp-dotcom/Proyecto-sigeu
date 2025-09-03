/* =====================================================================================================
PROYECTO: SIGEU – Sistema de Gestión de Eventos Universitarios
MÓDULO: VISTAS DE CONTROL
VERSIÓN: 1.0
FECHA: 2025-09-02 04:01
AUTORES (equipo): David Hernández, Sebastián Manrique, Daniel Brand, Michael Cardona, Andrés Gómez
DESCRIPCIÓN:
  Este script crea vistas lógicas (CREATE VIEW) para soporte operativo y auditoría.
  Están pensadas para tableros (dashboards), reportes rápidos y controles de calidad.
REQUISITOS:
  - Esquema 'sigeu' ya creado y con tablas pobladas.
  - MySQL 8+ recomendado.

CONVENCIÓN:
  - Prefijo v_ para vistas.
  - Comentarios extensos para facilitar sustentación.
===================================================================================================== */

USE sigeu;

/* =====================================================================================================
VISTA: v_eventos_en_revision
QUÉ HACE:
  - Lista todos los eventos cuyo estado es 'en_revision' con la información mínima necesaria para priorizar análisis:
    título, tipo_evento, categoría, fechas, organizador (nombre, rol) y la instalación asignada.
PROPÓSITO / PARA QUÉ:
  - Sirve como tablero de pendientes del comité/secretaría para ordenar la cola de evaluación y asignar revisores.
PREGUNTAS QUE RESPONDE:
  - ¿Qué eventos siguen esperando evaluación?
  - ¿Quién los organizó y en qué espacio se realizarán?
STAKEHOLDERS: Secretaría Académica, Comité de Eventos, Coordinaciones de Unidad.
TABLAS Y CAMPOS CLAVE:
  - evento (id_evento, titulo, tipo_evento, categoria, fecha_inicio, fecha_fin, estado, organizador_id, id_instalacion)
  - usuario (id_usuario, nombre, rol)
  - instalacion (id_instalacion, nombre)
RELACIONES (PK → FK):
  - evento.organizador_id → usuario.id_usuario
  - evento.id_instalacion → instalacion.id_instalacion
FILTROS Y SUPUESTOS:
  - Incluye únicamente e.estado = 'en_revision'.
  - Se asume que todo evento en revisión tiene instalación asignada.
IMPORTANCIA:
  - Fuente de verdad para la cola de revisión; facilita SLAs y tiempos de respuesta.
EJEMPLO DE USO:
  - SELECT * FROM v_eventos_en_revision ORDER BY fecha_inicio;
===================================================================================================== */
CREATE OR REPLACE VIEW v_eventos_en_revision AS
SELECT e.id_evento, e.titulo, e.tipo_evento, e.categoria,
       e.fecha_inicio, e.fecha_fin,
       u.nombre AS organizador, u.rol AS rol_organizador,
       i.nombre AS instalacion
FROM evento e
JOIN usuario     u ON u.id_usuario = e.organizador_id
JOIN instalacion i ON i.id_instalacion = e.id_instalacion
WHERE e.estado = 'en_revision';


/* =====================================================================================================
VISTA: v_eventos_aprobados_sin_acta
QUÉ HACE:
  - Detecta eventos en estado 'aprobado' que no tienen acta de comité registrada (documento obligatorio).
PROPÓSITO / PARA QUÉ:
  - Control de cumplimiento documental post-aprobación; evita publicación sin respaldo formal.
PREGUNTAS QUE RESPONDE:
  - ¿Qué eventos aprobados carecen aún de su acta en PDF?
TABLAS:
  - evento (id_evento, titulo, estado, fecha_inicio, fecha_fin)
  - acta_comite (evento_id)
RELACIONES:
  - LEFT JOIN acta_comite ON a.evento_id = e.id_evento (se espera NULL si falta el acta)
IMPORTANCIA:
  - Indicador crítico de trazabilidad y auditoría.
===================================================================================================== */
CREATE OR REPLACE VIEW v_eventos_aprobados_sin_acta AS
SELECT e.id_evento, e.titulo, e.fecha_inicio, e.fecha_fin
FROM evento e
LEFT JOIN acta_comite a ON a.evento_id = e.id_evento
WHERE e.estado = 'aprobado' AND a.id_acta IS NULL;


/* =====================================================================================================
VISTA: v_responsables_por_unidad
QUÉ HACE:
  - Muestra, para cada evento y unidad organizadora (N:M), el/los responsables asignados y su rol.
PROPÓSITO:
  - Trazabilidad de responsables (estudiante/docente) por unidad; soporte para asignación y seguimiento.
TABLAS:
  - evento (id_evento, titulo)
  - evento_unidad (id_evento_unidad, id_evento, id_unidad)
  - unidad_academica (id_unidad, nombre)
  - responsable_asignado (evento_unidad_id, id_responsable, usuario_id, rol_en_evento)
  - usuario (id_usuario, nombre)
RELACIONES:
  - e.id_evento = eu.id_evento
  - eu.id_unidad = ua.id_unidad
  - r.evento_unidad_id = eu.id_evento_unidad (LEFT JOIN para permitir unidades sin responsable)
  - r.usuario_id = ur.id_usuario
USO:
  - Verificar que cada (evento, unidad) tenga ≥ 1 responsable visible.
===================================================================================================== */
CREATE OR REPLACE VIEW v_responsables_por_unidad AS
SELECT e.id_evento, e.titulo,
       ua.id_unidad, ua.nombre AS unidad,
       r.id_responsable, ur.nombre AS responsable, r.rol_en_evento
FROM evento e
JOIN evento_unidad      eu ON eu.id_evento = e.id_evento
JOIN unidad_academica   ua ON ua.id_unidad = eu.id_unidad
LEFT JOIN responsable_asignado r ON r.evento_unidad_id = eu.id_evento_unidad
LEFT JOIN usuario            ur ON ur.id_usuario = r.usuario_id;


/* =====================================================================================================
VISTA: v_eventos_con_unidades_sin_responsable
QUÉ HACE:
  - Lista todas las combinaciones (evento, unidad) que no tienen ningún responsable asignado.
PROPÓSITO:
  - Checklist de inconsistencias a resolver antes de evaluación (regla de negocio del enunciado).
RELACIONES:
  - Mismas que la vista anterior; filtra por r.id_responsable IS NULL.
IMPORTANCIA:
  - Evita rechazos, asegura claridad de dueños por unidad.
===================================================================================================== */
CREATE OR REPLACE VIEW v_eventos_con_unidades_sin_responsable AS
SELECT e.id_evento, e.titulo, ua.id_unidad, ua.nombre AS unidad
FROM evento e
JOIN evento_unidad    eu ON eu.id_evento = e.id_evento
JOIN unidad_academica ua ON ua.id_unidad = eu.id_unidad
LEFT JOIN responsable_asignado r ON r.evento_unidad_id = eu.id_evento_unidad
WHERE r.id_responsable IS NULL;


/* =====================================================================================================
VISTA: v_participacion_organizaciones
QUÉ HACE:
  - Expone la participación de organizaciones externas en eventos, incluyendo quién asiste y el certificado PDF.
PROPÓSITO:
  - Trazabilidad con terceros; evidencia documental y logística.
TABLAS:
  - evento (id_evento, titulo)
  - participacion_org (evento_id, organizacion_id, participa_rep_legal, representante_participante, url_certificado_pdf)
  - organizacion_externa (id_organizacion, nombre, representante_legal)
REGLA DE NEGOCIO:
  - Siempre debe existir url_certificado_pdf cuando hay participación.
===================================================================================================== */
CREATE OR REPLACE VIEW v_participacion_organizaciones AS
SELECT e.id_evento, e.titulo,
       oe.id_organizacion, oe.nombre AS organizacion,
       po.participa_rep_legal,
       CASE WHEN po.participa_rep_legal = 1 THEN oe.representante_legal
            ELSE po.representante_participante END AS representante_que_asiste,
       po.url_certificado_pdf
FROM evento e
JOIN participacion_org    po ON po.evento_id = e.id_evento
JOIN organizacion_externa oe ON oe.id_organizacion = po.organizacion_id;


/* =====================================================================================================
VISTA: v_eventos_pendientes_aval
QUÉ HACE:
  - Muestra eventos sin registro de aval (requisito del enunciado).
USO:
  - Filtro de control previo a aprobación/publicación.
===================================================================================================== */
CREATE OR REPLACE VIEW v_eventos_pendientes_aval AS
SELECT e.id_evento, e.titulo, e.estado
FROM evento e
LEFT JOIN aval a ON a.evento_id = e.id_evento
WHERE a.id_aval IS NULL;


/* =====================================================================================================
VISTA: v_notificaciones_por_evento
QUÉ HACE:
  - Historial de notificaciones por evento (aprobación/rechazo) con fecha y destinatario.
PROPÓSITO:
  - Evidencia de comunicación; auditoría y soporte a reclamaciones.
===================================================================================================== */
CREATE OR REPLACE VIEW v_notificaciones_por_evento AS
SELECT e.id_evento, e.titulo,
       n.id_notificacion, n.tipo, n.justificacion, n.fecha_envio,
       u.nombre AS destinatario
FROM evento e
JOIN notificacion n ON n.evento_id = e.id_evento
JOIN usuario     u ON u.id_usuario = n.destinatario_id;


/* =====================================================================================================
VISTA: v_contrasena_vigente
QUÉ HACE:
  - Muestra la contraseña vigente por usuario (refuerzo visual a la regla del trigger).
===================================================================================================== */
CREATE OR REPLACE VIEW v_contrasena_vigente AS
SELECT u.id_usuario, u.nombre, hc.id_contrasena, hc.fecha_inicio, hc.fecha_fin, hc.vigente
FROM usuario u
JOIN historial_contrasena hc ON hc.id_usuario = u.id_usuario
WHERE hc.vigente = 1;


/* =====================================================================================================
VISTA: v_agenda_eventos
QUÉ HACE:
  - Agenda operacional: fechas, estado e instalación asignada.
USO:
  - Planificación de espacios, equipos y comunicaciones.
===================================================================================================== */
CREATE OR REPLACE VIEW v_agenda_eventos AS
SELECT e.id_evento, e.titulo, e.fecha_inicio, e.fecha_fin, e.estado,
       i.nombre AS instalacion, i.tipo AS tipo_instalacion
FROM evento e
JOIN instalacion i ON i.id_instalacion = e.id_instalacion
ORDER BY e.fecha_inicio;


/* =====================================================================================================
VISTA: v_eventos_por_unidad
QUÉ HACE:
  - Mapea la relación N:M evento–unidad para ver distribución por dependencia.
USO:
  - Reportes por unidad académica y carga por estado.
===================================================================================================== */
CREATE OR REPLACE VIEW v_eventos_por_unidad AS
SELECT ua.id_unidad, ua.nombre AS unidad,
       e.id_evento, e.titulo, e.estado
FROM unidad_academica ua
JOIN evento_unidad eu ON eu.id_unidad = ua.id_unidad
JOIN evento e         ON e.id_evento = eu.id_evento;
