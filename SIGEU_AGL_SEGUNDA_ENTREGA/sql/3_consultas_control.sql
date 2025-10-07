-- 3_consultas_control.sql
USE uao_eventos;

-- 1) Últimos eventos con organizador e instalación
SELECT e.idEvento, e.nombre, e.estado, u.nombre AS organizador, i.nombre AS instalacion
FROM evento e
JOIN usuario u ON u.idUsuario = e.idOrganizador
JOIN instalacion i ON i.idInstalacion = e.idInstalacion
ORDER BY e.idEvento DESC
LIMIT 10;

-- 2) Verificar que solo Docente/Estudiante estén en usuarioEvento
SELECT ue.idEvento, ue.idUsuario, u.rol
FROM usuarioEvento ue
JOIN usuario u ON u.idUsuario = ue.idUsuario
WHERE u.rol NOT IN ('docente','estudiante');

-- 3) Validar unicidad de principal por evento
SELECT idEvento, SUM(principal='S') AS cant_principales
FROM usuarioEvento
GROUP BY idEvento
HAVING cant_principales > 1;

-- 4) Conteo de eventos por estado
SELECT estado, COUNT(*) AS total
FROM evento
GROUP BY estado
ORDER BY total DESC;

-- 5) Últimas notificaciones (ajustada a la estructura real)
--    Incluye idEvento mediante JOIN con evaluacion
SELECT n.idNotificacion,
       ev.idEvento,
       n.tipoNotificacion,
       n.fechaEnvio,
       n.justificacion AS mensaje,
       n.urlPDF,
       n.usuarioReceptor
FROM notificacion n
JOIN evaluacion ev ON ev.idEvaluacion = n.idEvaluacion
ORDER BY n.idNotificacion DESC
LIMIT 20;