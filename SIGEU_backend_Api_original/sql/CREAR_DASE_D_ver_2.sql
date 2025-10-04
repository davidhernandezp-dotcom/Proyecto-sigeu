-- Crear BD y tablas (versión 2)
DROP DATABASE IF EXISTS uao_eventos;
CREATE DATABASE uao_eventos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE uao_eventos;

CREATE TABLE usuario (
  idUsuario BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  correo VARCHAR(150) NOT NULL UNIQUE,
  rol ENUM('docente','estudiante','secretarioAcademico') NOT NULL
);

CREATE TABLE credenciales (
  idCredencial BIGINT PRIMARY KEY AUTO_INCREMENT,
  idUsuario BIGINT NOT NULL,
  estado ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  password_hash VARCHAR(255) NOT NULL,
  fechaCambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cred_user FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
);

CREATE TABLE facultad (
  idFacultad BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  ubicacion VARCHAR(150) NULL
);

CREATE TABLE unidadAcademica (
  idUnidadAcademica BIGINT PRIMARY KEY AUTO_INCREMENT,
  idFacultad BIGINT NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  tipo ENUM('escuela','departamento','instituto','facultad') NOT NULL,
  CONSTRAINT fk_unidad_facultad FOREIGN KEY (idFacultad) REFERENCES facultad(idFacultad)
);

CREATE TABLE programa (
  idPrograma BIGINT PRIMARY KEY AUTO_INCREMENT,
  idUnidadAcademica BIGINT NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  CONSTRAINT fk_programa_unidad FOREIGN KEY (idUnidadAcademica) REFERENCES unidadAcademica(idUnidadAcademica)
);

CREATE TABLE docente (
  idDocente BIGINT PRIMARY KEY AUTO_INCREMENT,
  idUnidadAcademica BIGINT NOT NULL,
  idUsuario BIGINT NOT NULL UNIQUE,
  CONSTRAINT fk_docente_usuario FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario),
  CONSTRAINT fk_docente_unidad FOREIGN KEY (idUnidadAcademica) REFERENCES unidadAcademica(idUnidadAcademica)
);

CREATE TABLE estudiante (
  idEstudiante BIGINT PRIMARY KEY AUTO_INCREMENT,
  idPrograma BIGINT NOT NULL,
  idUsuario BIGINT NOT NULL UNIQUE,
  CONSTRAINT fk_est_programa FOREIGN KEY (idPrograma) REFERENCES programa(idPrograma),
  CONSTRAINT fk_est_usuario FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
);

CREATE TABLE secretariaAcademica (
  idSecretaria BIGINT PRIMARY KEY AUTO_INCREMENT,
  idFacultad BIGINT NOT NULL,
  idUsuario BIGINT NOT NULL UNIQUE,
  CONSTRAINT fk_sec_facultad FOREIGN KEY (idFacultad) REFERENCES facultad(idFacultad),
  CONSTRAINT fk_sec_usuario FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
);

CREATE TABLE instalacion (
  idInstalacion BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  tipo ENUM('salon','laboratorio','auditorio','otro') NOT NULL,
  capacidad INT NOT NULL CHECK (capacidad > 0),
  ubicacion VARCHAR(150) NOT NULL
);

CREATE TABLE organizacion (
  idOrganizacion BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(150) NOT NULL,
  representanteLegal VARCHAR(120) NOT NULL,
  actividadPrincipal VARCHAR(160) NOT NULL,
  telefono VARCHAR(40) NOT NULL,
  ubicacion VARCHAR(150) NOT NULL,
  sectorEconomico VARCHAR(120) NOT NULL
);

CREATE TABLE evento (
  idEvento BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(180) NOT NULL,
  descripcion TEXT,
  fechaInicio DATETIME NOT NULL,
  fechaFin DATETIME NOT NULL,
  estado ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
  categoria ENUM('academico','ludico') NOT NULL,
  idOrganizador BIGINT NOT NULL,
  idInstalacion BIGINT NOT NULL,
  rutaAvalPDF VARCHAR(255) NOT NULL,
  fechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evento_usuario FOREIGN KEY (idOrganizador) REFERENCES usuario(idUsuario),
  CONSTRAINT fk_evento_instal FOREIGN KEY (idInstalacion) REFERENCES instalacion(idInstalacion),
  CONSTRAINT chk_fechas_evento CHECK (fechaFin >= fechaInicio)
);

CREATE TABLE eventoUnidad (
  idEvento BIGINT NOT NULL,
  idUnidadAcademica BIGINT NOT NULL,
  idResponsable BIGINT NOT NULL,
  PRIMARY KEY (idEvento, idUnidadAcademica),
  CONSTRAINT fk_eu_evento FOREIGN KEY (idEvento) REFERENCES evento(idEvento) ON DELETE CASCADE,
  CONSTRAINT fk_eu_unidad FOREIGN KEY (idUnidadAcademica) REFERENCES unidadAcademica(idUnidadAcademica),
  CONSTRAINT fk_eu_responsable FOREIGN KEY (idResponsable) REFERENCES usuario(idUsuario)
);

CREATE TABLE eventoOrganizacion (
  idEventoOrganizacion BIGINT PRIMARY KEY AUTO_INCREMENT,
  idEvento BIGINT NOT NULL,
  idOrganizacion BIGINT NOT NULL,
  certificadoPDF VARCHAR(255) NULL,
  participante VARCHAR(120) NOT NULL,
  esRepresentanteLegal BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_eo_evento FOREIGN KEY (idEvento) REFERENCES evento(idEvento) ON DELETE CASCADE,
  CONSTRAINT fk_eo_org FOREIGN KEY (idOrganizacion) REFERENCES organizacion(idOrganizacion)
);

CREATE TABLE revision (
  idRevision BIGINT PRIMARY KEY AUTO_INCREMENT,
  idSecretariaAcademica BIGINT NOT NULL,
  idEvento BIGINT NOT NULL,
  comentarios TEXT,
  estado ENUM('aprobado','rechazado') NOT NULL,
  actaPDF VARCHAR(255) NULL,
  fechaRevision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rev_sec FOREIGN KEY (idSecretariaAcademica) REFERENCES secretariaAcademica(idSecretaria),
  CONSTRAINT fk_rev_evento FOREIGN KEY (idEvento) REFERENCES evento(idEvento)
);

CREATE TABLE notificacion (
  idNotificacion BIGINT PRIMARY KEY AUTO_INCREMENT,
  idRevision BIGINT NOT NULL,
  tipoNotificacion ENUM('aprobado','rechazado') NOT NULL,
  fechaEnvio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  justificacion TEXT NULL,
  urlPDF VARCHAR(255) NULL,
  usuarioReceptor BIGINT NOT NULL,
  CONSTRAINT fk_not_rev FOREIGN KEY (idRevision) REFERENCES revision(idRevision),
  CONSTRAINT fk_not_user FOREIGN KEY (usuarioReceptor) REFERENCES usuario(idUsuario)
);

CREATE TABLE log_auditoria (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  entidad VARCHAR(64) NOT NULL,
  entidad_id BIGINT NULL,
  accion ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  usuario_id BIGINT NULL,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  detalle JSON NULL
);
