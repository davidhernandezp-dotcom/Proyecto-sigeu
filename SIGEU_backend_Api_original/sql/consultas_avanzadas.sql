USE uao_eventos;

-- A1 | Tasa de aprobación por facultad (90 días)
WITH R AS (
  SELECT r.idEvento, r.estado, r.fechaRevision
  FROM revision r
  WHERE r.fechaRevision >= NOW() - INTERVAL 90 DAY
), EU AS (
  SELECT e.idEvento, ua.idFacultad
  FROM evento e
  JOIN eventoUnidad eu ON e.idEvento=eu.idEvento
  JOIN unidadAcademica ua ON ua.idUnidadAcademica=eu.idUnidadAcademica
)
SELECT f.nombre AS facultad,
       SUM(R.estado='aprobado') AS aprobados,
       SUM(R.estado='rechazado') AS rechazados,
       COUNT(*) AS total,
       ROUND(SUM(R.estado='aprobado')/COUNT(*)*100,2) AS tasa_aprobacion_pct
FROM R JOIN EU USING(idEvento) JOIN facultad f ON f.idFacultad = EU.idFacultad
GROUP BY f.idFacultad
ORDER BY tasa_aprobacion_pct DESC;

-- A2 | Tiempo promedio de revisión por secretaría (horas)
SELECT sa.idSecretaria, u.nombre AS secretaria,
       ROUND(AVG(TIMESTAMPDIFF(HOUR, e.fechaRegistro, r.fechaRevision)),2) AS horas_promedio
FROM revision r
JOIN evento e ON e.idEvento=r.idEvento
JOIN secretariaAcademica sa ON sa.idSecretaria=r.idSecretariaAcademica
JOIN usuario u ON u.idUsuario=sa.idUsuario
GROUP BY sa.idSecretaria;

-- A3 | Uso de instalaciones entre @ini y @fin
-- SET @ini='2025-10-01', @fin='2025-12-31';
SELECT i.nombre AS instalacion, COUNT(*) AS eventos,
       ROUND(SUM(TIMESTAMPDIFF(MINUTE, e.fechaInicio, e.fechaFin))/60,2) AS horas_agendadas, i.capacidad
FROM evento e JOIN instalacion i ON i.idInstalacion=e.idInstalacion
WHERE e.fechaInicio BETWEEN @ini AND @fin
GROUP BY i.idInstalacion ORDER BY horas_agendadas DESC;

-- A4 | Antigüedad de pendientes por unidad
SELECT ua.nombre AS unidad, COUNT(*) AS pendientes,
       ROUND(AVG(DATEDIFF(NOW(), e.fechaRegistro)),2) AS edad_promedio,
       MAX(DATEDIFF(NOW(), e.fechaRegistro)) AS max_dias
FROM evento e JOIN eventoUnidad eu ON eu.idEvento=e.idEvento
JOIN unidadAcademica ua ON ua.idUnidadAcademica=eu.idUnidadAcademica
WHERE e.estado='pendiente'
GROUP BY ua.idUnidadAcademica ORDER BY pendientes DESC;

-- A5 | Top organizaciones y tasa de aprobación
WITH ult AS ( SELECT idEvento, MAX(fechaRevision) AS ult FROM revision GROUP BY idEvento ),
final AS ( SELECT r.idEvento, r.estado FROM revision r JOIN ult ON r.idEvento=ult.idEvento AND r.fechaRevision=ult.ult )
SELECT o.nombre, COUNT(eo.idEvento) AS veces, SUM(final.estado='aprobado') AS aprobados,
ROUND(SUM(final.estado='aprobado')/COUNT(eo.idEvento)*100,2) AS tasa
FROM eventoOrganizacion eo
JOIN organizacion o ON o.idOrganizacion=eo.idOrganizacion
LEFT JOIN final ON final.idEvento=eo.idEvento
GROUP BY o.idOrganizacion ORDER BY veces DESC;

-- A6 | Volumen mensual por categoría y facultad
SELECT DATE_FORMAT(e.fechaInicio, '%Y-%m') AS anio_mes, e.categoria, f.nombre AS facultad, COUNT(*) AS eventos
FROM evento e
JOIN eventoUnidad eu ON eu.idEvento=e.idEvento
JOIN unidadAcademica ua ON ua.idUnidadAcademica=eu.idUnidadAcademica
JOIN facultad f ON f.idFacultad=ua.idFacultad
GROUP BY anio_mes, e.categoria, f.idFacultad
ORDER BY anio_mes DESC, eventos DESC;

-- A7 | Eventos por rol del organizador
SELECT u.rol, COUNT(*) AS eventos
FROM evento e JOIN usuario u ON u.idUsuario=e.idOrganizador
GROUP BY u.rol ORDER BY eventos DESC;

-- A8 | Solapamientos por instalación
SELECT e1.idEvento AS evento1, e2.idEvento AS evento2, i.nombre AS instalacion
FROM evento e1
JOIN evento e2 ON e1.idInstalacion=e2.idInstalacion AND e1.idEvento<e2.idEvento
JOIN instalacion i ON i.idInstalacion=e1.idInstalacion
WHERE e1.fechaInicio < e2.fechaFin AND e2.fechaInicio < e1.fechaFin;

-- A9 | Capacidad vs duración
SELECT e.idEvento, e.nombre, i.capacidad,
       TIMESTAMPDIFF(MINUTE, e.fechaInicio, e.fechaFin) AS duracion_min
FROM evento e JOIN instalacion i ON i.idInstalacion=e.idInstalacion
ORDER BY i.capacidad DESC, duracion_min DESC;

-- A10 | Tasa de rechazo por unidad y categoría
WITH f AS (
  SELECT eu.idUnidadAcademica, e.categoria, SUM(r.estado='rechazado') AS rechazados, COUNT(*) AS total
  FROM revision r JOIN evento e ON e.idEvento=r.idEvento
  JOIN eventoUnidad eu ON eu.idEvento=e.idEvento
  GROUP BY eu.idUnidadAcademica, e.categoria
)
SELECT ua.nombre, categoria, rechazados, total, ROUND(rechazados/total*100,2) AS tasa_rechazo_pct
FROM f JOIN unidadAcademica ua ON ua.idUnidadAcademica=f.idUnidadAcademica
ORDER BY tasa_rechazo_pct DESC;

-- A11 | Días de anticipación por organizador
SELECT u.nombre, u.rol,
       ROUND(AVG(TIMESTAMPDIFF(DAY, e.fechaRegistro, e.fechaInicio)),2) AS dias_anticipacion
FROM evento e JOIN usuario u ON u.idUsuario=e.idOrganizador
GROUP BY u.idUsuario ORDER BY dias_anticipacion DESC;

-- A12 | Unidades con más aprobados (año actual)
SELECT ua.nombre, COUNT(*) AS eventos_aprobados
FROM evento e
JOIN revision r ON r.idEvento=e.idEvento AND r.estado='aprobado'
JOIN eventoUnidad eu ON eu.idEvento=e.idEvento
JOIN unidadAcademica ua ON ua.idUnidadAcademica=eu.idUnidadAcademica
WHERE YEAR(e.fechaInicio) = YEAR(CURDATE())
GROUP BY ua.idUnidadAcademica
ORDER BY eventos_aprobados DESC;

-- A13 | Último estado por evento
WITH ult2 AS ( SELECT idEvento, MAX(fechaRevision) AS ult FROM revision GROUP BY idEvento )
SELECT e.idEvento, e.nombre, r.estado, r.fechaRevision
FROM ult2 JOIN revision r ON r.idEvento=ult2.idEvento AND r.fechaRevision=ult2.ult
JOIN evento e ON e.idEvento=r.idEvento;

-- A14 | Días y horas pico
SELECT DAYNAME(e.fechaInicio) AS dia_semana, HOUR(e.fechaInicio) AS hora, COUNT(*) AS eventos
FROM evento e GROUP BY dia_semana, hora ORDER BY eventos DESC;

-- A15 | Productividad por secretaría (mensual)
SELECT DATE_FORMAT(r.fechaRevision, '%Y-%m') AS anio_mes, sa.idSecretaria, u.nombre,
       SUM(r.estado='aprobado') AS aprobados, COUNT(*) AS revisiones
FROM revision r
JOIN secretariaAcademica sa ON sa.idSecretaria=r.idSecretariaAcademica
JOIN usuario u ON u.idUsuario=sa.idUsuario
GROUP BY anio_mes, sa.idSecretaria
ORDER BY anio_mes DESC, aprobados DESC;
