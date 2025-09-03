-- ====== BASE DE DATOS ======
DROP DATABASE IF EXISTS sigeu;
CREATE DATABASE sigeu CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sigeu;

-- ====== TABLAS BÁSICAS ======

-- Usuarios del sistema
CREATE TABLE usuario (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE,
  -- Roles mínimos del enunciado + 2 directivos para validaciones de aval
  rol ENUM('estudiante','docente','secretarioAcademico','directorPrograma','directorDocencia','admin') NOT NULL,
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

-- Historial de contraseñas (una vigente por usuario)
CREATE TABLE historial_contrasena (
  id_contrasena INT PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  hash VARCHAR(255) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  vigente TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Instalaciones / espacios físicos
CREATE TABLE instalacion (
  id_instalacion INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  tipo ENUM('salon','laboratorio','auditorio','otro') NOT NULL,
  capacidad INT NOT NULL,
  ubicacion VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Unidades académicas
CREATE TABLE unidad_academica (
  id_unidad INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  tipo VARCHAR(50) NOT NULL    -- p.ej. 'facultad', 'programa'
) ENGINE=InnoDB;

-- Eventos
CREATE TABLE evento (
  id_evento INT PRIMARY KEY AUTO_INCREMENT,
  titulo VARCHAR(120) NOT NULL,
  tipo_evento ENUM('academico','ludico') NOT NULL,
  categoria VARCHAR(50) NOT NULL,           -- seminario, taller, curso, etc.
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  estado ENUM('borrador','en_revision','aprobado','rechazado','publicado') NOT NULL DEFAULT 'borrador',
  organizador_id INT NOT NULL,              -- FK a usuario (estudiante o docente)
  id_instalacion INT NOT NULL,              -- evento se realiza en UNA instalación
  FOREIGN KEY (organizador_id) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  FOREIGN KEY (id_instalacion) REFERENCES instalacion(id_instalacion) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- N:M Evento - Unidad académica
CREATE TABLE evento_unidad (
  id_evento_unidad INT PRIMARY KEY AUTO_INCREMENT,
  id_evento INT NOT NULL,
  id_unidad INT NOT NULL,
  UNIQUE (id_evento, id_unidad),
  FOREIGN KEY (id_evento) REFERENCES evento(id_evento) ON DELETE CASCADE,
  FOREIGN KEY (id_unidad) REFERENCES unidad_academica(id_unidad) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Responsables por (evento, unidad)
CREATE TABLE responsable_asignado (
  id_responsable INT PRIMARY KEY AUTO_INCREMENT,
  evento_unidad_id INT NOT NULL,
  usuario_id INT NOT NULL,                 -- docente o estudiante
  rol_en_evento VARCHAR(50) NOT NULL,      -- p.ej. 'responsable', 'coordinador'
  FOREIGN KEY (evento_unidad_id) REFERENCES evento_unidad(id_evento_unidad) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Aval 1:1 con evento (PDF obligatorio, emisor correcto)
CREATE TABLE aval (
  id_aval INT PRIMARY KEY AUTO_INCREMENT,
  evento_id INT NOT NULL UNIQUE,           -- garantiza 1:1
  emisor_usuario_id INT NOT NULL,          -- directorPrograma o directorDocencia
  url_pdf VARCHAR(255) NOT NULL,
  fecha DATE NOT NULL,
  FOREIGN KEY (evento_id) REFERENCES evento(id_evento) ON DELETE RESTRICT,
  FOREIGN KEY (emisor_usuario_id) REFERENCES usuario(id_usuario) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Acta de comité (0..1 por evento) cuando aprobado
CREATE TABLE acta_comite (
  id_acta INT PRIMARY KEY AUTO_INCREMENT,
  evento_id INT NOT NULL UNIQUE,
  url_pdf VARCHAR(255) NOT NULL,
  fecha DATE NOT NULL,
  FOREIGN KEY (evento_id) REFERENCES evento(id_evento) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Organizaciones externas
CREATE TABLE organizacion_externa (
  id_organizacion INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  representante_legal VARCHAR(100) NOT NULL,
  telefono VARCHAR(30) NOT NULL,
  ubicacion VARCHAR(120) NOT NULL,
  sector_economico VARCHAR(60) NOT NULL,
  actividad_principal VARCHAR(100) NOT NULL,
  registrado ENUM('si','no') NOT NULL DEFAULT 'si'
) ENGINE=InnoDB;

-- N:M Evento - Organización externa, con certificado PDF
CREATE TABLE participacion_org (
  id_participacion INT PRIMARY KEY AUTO_INCREMENT,
  evento_id INT NOT NULL,
  organizacion_id INT NOT NULL,
  participa_rep_legal TINYINT(1) NOT NULL,
  representante_participante VARCHAR(100) NULL,
  url_certificado_pdf VARCHAR(255) NOT NULL,
  UNIQUE (evento_id, organizacion_id),
  FOREIGN KEY (evento_id) REFERENCES evento(id_evento) ON DELETE CASCADE,
  FOREIGN KEY (organizacion_id) REFERENCES organizacion_externa(id_organizacion) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Notificaciones al organizador
CREATE TABLE notificacion (
  id_notificacion INT PRIMARY KEY AUTO_INCREMENT,
  evento_id INT NOT NULL,
  destinatario_id INT NOT NULL,                          -- organizador (usuario)
  tipo ENUM('aprobacion','rechazo') NOT NULL,
  justificacion VARCHAR(200) NULL,                       -- obligatoria si rechazo
  fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (evento_id) REFERENCES evento(id_evento) ON DELETE CASCADE,
  FOREIGN KEY (destinatario_id) REFERENCES usuario(id_usuario) ON DELETE RESTRICT
) ENGINE=InnoDB;
