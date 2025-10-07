USE uao_eventos;

-- Vista base para reportes de eventos (organizador + instalación + métricas)

CREATE OR REPLACE VIEW vi_eventos_base AS
SELECT
    e.idEvento,
    e.nombre,
    e.descripcion,
    e.categoria,
    e.estado,
    e.fechaInicio,
    e.fechaFin,
    TIMESTAMPDIFF(HOUR, e.fechaInicio, e.fechaFin) AS duracion_horas,
    e.fechaRegistro,
    e.rutaAvalPDF,

    e.idOrganizador,
    u.nombre AS organizador_nombre,
    u.rol     AS organizador_rol,

    e.idInstalacion,
    i.nombre AS instalacion_nombre,
    i.tipo   AS instalacion_tipo,
    i.capacidad AS instalacion_capacidad
FROM evento e
JOIN usuario u      ON u.idUsuario      = e.idOrganizador
JOIN instalacion i  ON i.idInstalacion  = e.idInstalacion;
