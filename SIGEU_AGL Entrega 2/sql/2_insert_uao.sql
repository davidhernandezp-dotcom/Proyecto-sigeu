USE uao_eventos;

-- =========================================================
-- USUARIOS (20)
-- =========================================================
INSERT INTO usuario (nombre, correo, rol) VALUES
('Carlos Perez','carlos.perez@uao.edu.co','docente'),
('Maria Gomez','maria.gomez@uao.edu.co','estudiante'),
('Juan Lopez','juan.lopez@uao.edu.co','docente'),
('Laura Moreno','laura.moreno@uao.edu.co','estudiante'),
('Andres Torres','andres.torres@uao.edu.co','docente'),
('Paula Ramirez','paula.ramirez@uao.edu.co','estudiante'),
('Diego Martinez','diego.martinez@uao.edu.co','docente'),
('Ana Rodriguez','ana.rodriguez@uao.edu.co','estudiante'),
('Felipe Sosa','felipe.sosa@uao.edu.co','docente'),
('Natalia Rios','natalia.rios@uao.edu.co','estudiante'),
('Sergio Vargas','sergio.vargas@uao.edu.co','docente'),
('Luisa Arias','luisa.arias@uao.edu.co','estudiante'),
('David Castaño','david.castano@uao.edu.co','docente'),
('Juliana Silva','juliana.silva@uao.edu.co','estudiante'),
('Camilo Ortiz','camilo.ortiz@uao.edu.co','docente'),
('Valentina Paz','valentina.paz@uao.edu.co','estudiante'),
('Mateo Sanchez','mateo.sanchez@uao.edu.co','docente'),
('Sofia Herrera','sofia.herrera@uao.edu.co','estudiante'),
('Javier Nino','javier.nino@uao.edu.co','docente'),
('Daniela Calle','daniela.calle@uao.edu.co','secretariaAcademica');

-- =========================================================
-- CONTRASENAS (hash simbólico)
-- Campo correcto: password_hash + estado
-- =========================================================
INSERT INTO contrasena (idUsuario, password_hash, estado) VALUES
(1,  '$2b$12$hash1',  'activa'), (2, '$2b$12$hash2',  'activa'),
(3,  '$2b$12$hash3',  'activa'), (4, '$2b$12$hash4',  'activa'),
(5,  '$2b$12$hash5',  'activa'), (6, '$2b$12$hash6',  'activa'),
(7,  '$2b$12$hash7',  'activa'), (8, '$2b$12$hash8',  'activa'),
(9,  '$2b$12$hash9',  'activa'), (10,'$2b$12$hash10', 'activa'),
(11, '$2b$12$hash11', 'activa'), (12,'$2b$12$hash12', 'activa'),
(13, '$2b$12$hash13', 'activa'), (14,'$2b$12$hash14', 'activa'),
(15, '$2b$12$hash15', 'activa'), (16,'$2b$12$hash16', 'activa'),
(17, '$2b$12$hash17', 'activa'), (18,'$2b$12$hash18', 'activa'),
(19, '$2b$12$hash19', 'activa'), (20,'$2b$12$hash20', 'activa');

-- =========================================================
-- INSTALACIONES
-- =========================================================
INSERT INTO instalacion (nombre, tipo, capacidad, ubicacion) VALUES
('Auditorio Principal','auditorio',300,'Bloque A - Piso 1'),
('Laboratorio 3','laboratorio',35,'Bloque C - Piso 2'),
('Salon 201','salon',50,'Bloque B - Piso 2');

-- =========================================================
-- ORGANIZACIONES (completas según diccionario)
-- =========================================================
INSERT INTO organizacion (nombre, representanteLegal, actividadPrincipal, telefono, ubicacion, sectorEconomico) VALUES
('Comunidad AI Cali','Laura Ruiz','Promoción de IA responsable','3160000001','Calle 10 #45-12','Tecnologia'),
('Fundacion Talentos','Miguel Hoyos','Formación artística juvenil','3160000002','Av. 3N #55-21','Cultura');

-- =========================================================
-- EVENTOS (3 de muestra)
-- =========================================================
INSERT INTO evento (nombre, descripcion, idOrganizador, idInstalacion, fechaInicio, fechaFin, categoria, estado, rutaAvalPDF)
VALUES
('Seminario IA UAO','Charlas sobre ML',1,2,'2025-11-05 08:00:00','2025-11-05 12:00:00','academico','registrado','/avales/aval1.pdf'),
('Festival de Talentos UAO','Musica y artes escenicas',2,1,'2025-11-10 18:00:00','2025-11-10 21:30:00','ludico','registrado','/avales/aval_evento2.pdf'),
('Jornada de Robotica','Exhibicion interfacultades',3,2,'2025-11-15 09:00:00','2025-11-15 17:00:00','academico','enRevision','/avales/aval_rob1.pdf');

-- =========================================================
-- USUARIOEVENTO (organizador principal y apoyos)
-- =========================================================
-- Organizadores principales (uno por evento)
INSERT INTO usuarioEvento (idUsuario, idEvento, principal) VALUES
(1,1,'S'),(2,2,'S'),(3,3,'S');

-- Apoyos (principal = 'N')
INSERT INTO usuarioEvento (idUsuario, idEvento, principal) VALUES
(4,1,'N'),(6,1,'N'),(5,3,'N');

-- =========================================================
-- EVENTOINSTALACION (instalaciones adicionales)
-- =========================================================
INSERT INTO eventoInstalacion (idEvento, idInstalacion) VALUES
(1,1),(1,3);

-- =========================================================
-- EVENTO-ORGANIZACION (ajustado a columnas reales)
-- =========================================================
INSERT INTO eventoOrganizacion (idEvento, idOrganizacion, certificadoPDF, participante, esRepresentanteLegal) VALUES
(1,1,'/cert/aliado1.pdf','Laura Ruiz',0),
(2,2,'/cert/patro2.pdf','Miguel Hoyos',1);

-- =========================================================
-- EVALUACIONES (para probar triggers de estado y notificación)
-- =========================================================
-- Evento 3 pasa a Aprobado
INSERT INTO evaluacion (idEvento, comentarios, estado, actaPDF, fechaRevision)
VALUES (3,'Evaluacion positiva del comite','aprobado','/actas/acta_ev3.pdf','2025-10-20 10:00:00');

-- Evento 2 pasa a Rechazado
INSERT INTO evaluacion (idEvento, comentarios, estado, actaPDF, fechaRevision)
VALUES (2,'No cumple requisitos de seguridad','rechazado','/actas/acta_ev2.pdf','2025-10-21 09:30:00');

-- (Los triggers actualizarán evento.estado y crearán registros en notificacion)
