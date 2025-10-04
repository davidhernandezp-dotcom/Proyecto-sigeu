USE uao_eventos;

-- 1. Correos con dominio UAO
SELECT idUsuario, nombre, correo FROM usuario WHERE correo LIKE '%@uao.edu.co';

-- 2. Eventos con fechas correctas
SELECT idEvento, nombre, fechaInicio, fechaFin FROM evento WHERE fechaFin >= fechaInicio;

-- 3. Máx. 1 credencial activa por usuario
SELECT idUsuario, SUM(estado='activa') AS activas
FROM credenciales GROUP BY idUsuario HAVING activas <= 1;

-- 4. Eventos pendientes sin revisión
SELECT e.idEvento, e.nombre
FROM evento e
LEFT JOIN revision r ON r.idEvento = e.idEvento
WHERE r.idRevision IS NULL AND e.estado='pendiente';

-- 5. Unidades responsables válidas
SELECT eu.idEvento, eu.idUnidadAcademica, ua.nombre
FROM eventoUnidad eu
JOIN unidadAcademica ua USING(idUnidadAcademica);
