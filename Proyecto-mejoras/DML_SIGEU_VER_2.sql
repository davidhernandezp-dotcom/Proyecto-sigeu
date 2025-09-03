-- ====== USUARIOS ====== DML (datos de prueba)
INSERT INTO usuario (nombre, correo, rol) VALUES
 ('Ana Estudiante','ana@uao.edu','estudiante'),
 ('Diego Docente','diego@uao.edu','docente'),
 ('Sofía Secretaria','sofia@uao.edu','secretarioAcademico'),
 ('Luis Dir. Programa','luis.dp@uao.edu','directorPrograma'),
 ('Marta Dir. Docencia','marta.dd@uao.edu','directorDocencia');

-- contraseñas (hashes de ejemplo)
INSERT INTO historial_contrasena (id_usuario, hash, fecha_inicio, vigente) VALUES
 (1,'hash_ana_1','2025-01-10',1),
 (2,'hash_diego_1','2025-01-10',1),
 (3,'hash_sofia_1','2025-01-10',1),
 (4,'hash_luis_1','2025-01-10',1),
 (5,'hash_marta_1','2025-01-10',1);

-- ====== INSTALACIONES ======
INSERT INTO instalacion (nombre,tipo,capacidad,ubicacion) VALUES
 ('Auditorio Central','auditorio',300,'Bloque A'),
 ('Lab Bases de Datos','laboratorio',40,'Bloque B - 302'),
 ('Salón 201','salon',60,'Bloque C - 201');

-- ====== UNIDADES ACADÉMICAS ======
INSERT INTO unidad_academica (nombre,tipo) VALUES
 ('Ingeniería de Sistemas','programa'),
 ('Facultad de Ingeniería','facultad'),
 ('Departamento de Matemáticas','departamento');

-- ====== EVENTOS ======
-- Evento 1: organizado por estudiante
INSERT INTO evento (titulo,tipo_evento,categoria,fecha_inicio,fecha_fin,estado,organizador_id,id_instalacion)
VALUES ('Semana de la Programación','academico','taller','2025-09-10','2025-09-12','en_revision',1,1);

-- Evento 2: organizado por docente
INSERT INTO evento (titulo,tipo_evento,categoria,fecha_inicio,fecha_fin,estado,organizador_id,id_instalacion)
VALUES ('Jornada de Innovación Docente','academico','seminario','2025-10-05','2025-10-05','en_revision',2,3);

-- ====== EVENTO-UNIDAD ======
INSERT INTO evento_unidad (id_evento,id_unidad) VALUES
 (1,1), (1,2),   -- evento 1 con programa y facultad
 (2,2);          -- evento 2 con facultad

-- ====== RESPONSABLES POR UNIDAD ======
-- Para evento 1 (estudiante organizador): responsables en ambas unidades
INSERT INTO responsable_asignado (evento_unidad_id, usuario_id, rol_en_evento) VALUES
 (1,1,'responsable'),  -- Ana en Ing. Sistemas
 (2,1,'responsable');  -- Ana en Facultad

-- Para evento 2 (docente organizador): responsable en facultad
INSERT INTO responsable_asignado (evento_unidad_id, usuario_id, rol_en_evento) VALUES
 (3,2,'responsable');  -- Diego en Facultad

-- ====== ORGANIZACIONES EXTERNAS ======
INSERT INTO organizacion_externa (nombre,representante_legal,telefono,ubicacion,sector_economico,actividad_principal,registrado) VALUES
 ('TechCorp S.A.S.','Juan Pérez','3001112233','Parque Tecnológico','TIC','Desarrollo de software','si'),
 ('Fundación Cultural','Laura Gómez','3002223344','Centro Cultural','Cultura','Gestión cultural','si');

-- ====== PARTICIPACIÓN ORG (con certificado) ======
INSERT INTO participacion_org (evento_id,organizacion_id,participa_rep_legal,representante_participante,url_certificado_pdf) VALUES
 (1,1,1,NULL,'/pdfs/cert_TechCorp_ev1.pdf'),
 (2,2,0,'Carlos Ruiz','/pdfs/cert_Fundacion_ev2.pdf');

-- ====== NOTIFICACIONES ======
INSERT INTO notificacion (evento_id,destinatario_id,tipo,justificacion)
VALUES
 (1,1,'rechazo','Falta aval PDF.'),          -- disparará regla de justificación (ok)
 (2,2,'aprobacion',NULL);

-- ====== AVAL (1:1) ======
-- Para evento 1 (organizador estudiante): emite Director de Programa (usuario id=4)
INSERT INTO aval (evento_id, emisor_usuario_id, url_pdf, fecha)
VALUES (1,4,'/pdfs/aval_ev1.pdf','2025-09-03');

-- Para evento 2 (organizador docente): emite Director de Docencia (usuario id=5)
INSERT INTO aval (evento_id, emisor_usuario_id, url_pdf, fecha)
VALUES (2,5,'/pdfs/aval_ev2.pdf','2025-10-01');

-- ====== ACTA COMITÉ (opcional, cuando aprobado) ======
-- Simulamos aprobación del evento 2 y su acta
UPDATE evento SET estado = 'aprobado' WHERE id_evento = 2;
INSERT INTO acta_comite (evento_id, url_pdf, fecha)
VALUES (2,'/pdfs/acta_ev2.pdf','2025-10-06');
