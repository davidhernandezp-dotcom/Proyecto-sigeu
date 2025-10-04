USE uao_eventos;

INSERT INTO facultad (nombre, ubicacion) VALUES
('Facultad de Ingeniería', 'Bloque A'),
('Facultad de Ciencias Económicas', 'Bloque B');

INSERT INTO unidadAcademica (idFacultad, nombre, tipo) VALUES
(1, 'Escuela de Ingeniería Informática', 'escuela'),
(2, 'Departamento de Estadística', 'departamento');

INSERT INTO programa (idUnidadAcademica, nombre) VALUES
(1, 'Ingeniería Informática'),
(2, 'Estadística Aplicada');

INSERT INTO usuario (nombre, correo, rol) VALUES
('Carlos Pérez', 'carlos.perez@uao.edu.co', 'docente'),
('Ana Gómez', 'ana.gomez@uao.edu.co', 'estudiante'),
('Juan Rivas', 'juan.rivas@uao.edu.co', 'secretarioAcademico');

INSERT INTO docente (idUnidadAcademica, idUsuario) VALUES (1, 1);
INSERT INTO estudiante (idPrograma, idUsuario) VALUES (2, 2);
INSERT INTO secretariaAcademica (idFacultad, idUsuario) VALUES (1, 3);

INSERT INTO instalacion (nombre, tipo, capacidad, ubicacion) VALUES
('Auditorio Central', 'auditorio', 400, 'Bloque A - Piso 1'),
('Laboratorio de Datos', 'laboratorio', 40, 'Bloque A - Piso 2');

INSERT INTO organizacion (nombre, representanteLegal, actividadPrincipal, telefono, ubicacion, sectorEconomico) VALUES
('UAO Tech', 'Luis Pardo', 'Proyectos de Innovación', '3001234567', 'Cali', 'Tecnología'),
('Cultura Viva', 'María Torres', 'Eventos culturales', '3019876543', 'Cali', 'Social');

INSERT INTO evento (nombre, descripcion, fechaInicio, fechaFin, estado, categoria, idOrganizador, idInstalacion, rutaAvalPDF) VALUES
('Jornada de Ciencia de Datos', 'Charlas y talleres sobre IA y ML', '2025-10-28 08:00:00','2025-10-28 13:00:00','pendiente','academico',1,2,'/avales/aval_evento1.pdf'),
('Festival de Talentos UAO', 'Música y artes escénicas', '2025-11-10 18:00:00','2025-11-10 21:30:00','pendiente','ludico',2,1,'/avales/aval_evento2.pdf');

INSERT INTO eventoUnidad (idEvento, idUnidadAcademica, idResponsable) VALUES
(1, 1, 1),(2, 2, 2);

INSERT INTO eventoOrganizacion (idEvento, idOrganizacion, certificadoPDF, participante, esRepresentanteLegal) VALUES
(1, 1, '/certificados/uaotech.pdf', 'Luis Pardo', TRUE),
(2, 2, '/certificados/culturaviva.pdf', 'María Torres', FALSE);
