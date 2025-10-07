-- ====== RESET DB ======
DROP DATABASE IF EXISTS uao_eventos;
CREATE DATABASE uao_eventos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE uao_eventos;

-- Para seguridad referencial
SET FOREIGN_KEY_CHECKS = 0;

-- ====== DROPS en orden de dependencias ======
DROP TABLE IF EXISTS notificacion;
DROP TABLE IF EXISTS evaluacion;
DROP TABLE IF EXISTS eventoOrganizacion;
DROP TABLE IF EXISTS eventoInstalacion;
DROP TABLE IF EXISTS usuarioEvento;
DROP TABLE IF EXISTS evento;
DROP TABLE IF EXISTS organizacion;
DROP TABLE IF EXISTS instalacion;
DROP TABLE IF EXISTS contrasena;
DROP TABLE IF EXISTS usuario;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- USUARIO
-- =========================================================
CREATE TABLE usuario (
  idUsuario       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre          VARCHAR(120)             NOT NULL,
  correo          VARCHAR(150)             NOT NULL UNIQUE,
  rol             ENUM('docente','estudiante','secretariaAcademica') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- CONTRASENA
-- =========================================================
CREATE TABLE contrasena (
  idContrasena    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idUsuario       BIGINT UNSIGNED          NOT NULL,
  password_hash   VARCHAR(255)             NOT NULL,
  estado          ENUM('activa','inactiva') NOT NULL,
  fechaCambio     TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_contra_usuario
    FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- INSTALACION
-- =========================================================
CREATE TABLE instalacion (
  idInstalacion   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre          VARCHAR(120)             NOT NULL,
  tipo            ENUM('salon','laboratorio','auditorio','otro') NOT NULL,
  capacidad       INT                       NOT NULL,
  ubicacion       VARCHAR(150)             NOT NULL,
  CONSTRAINT chk_inst_capacidad CHECK (capacidad > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- ORGANIZACION
-- =========================================================
CREATE TABLE organizacion (
  idOrganizacion      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre              VARCHAR(150)        NOT NULL,
  representanteLegal  VARCHAR(120)        NOT NULL,
  actividadPrincipal  VARCHAR(160)        NOT NULL,
  telefono            VARCHAR(40)         NOT NULL,
  ubicacion           VARCHAR(150)        NOT NULL,
  sectorEconomico     VARCHAR(120)        NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- EVENTO
-- =========================================================
CREATE TABLE evento (
  idEvento        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre          VARCHAR(180)            NOT NULL,
  descripcion     TEXT                    NULL,
  fechaInicio     DATETIME                NOT NULL,
  fechaFin        DATETIME                NOT NULL,
  estado          ENUM('registrado','enRevision','aprobado','rechazado') NOT NULL,
  categoria       ENUM('academico','ludico') NOT NULL,
  idOrganizador   BIGINT UNSIGNED         NOT NULL,   -- FK usuario
  idInstalacion   BIGINT UNSIGNED         NOT NULL,   -- FK instalacion
  rutaAvalPDF     VARCHAR(255)            NOT NULL,
  fechaRegistro   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evento_organizador
    FOREIGN KEY (idOrganizador) REFERENCES usuario(idUsuario)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_evento_instalacion
    FOREIGN KEY (idInstalacion) REFERENCES instalacion(idInstalacion)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_evento_fechas CHECK (fechaFin >= fechaInicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- USUARIOEVENTO
-- =========================================================
CREATE TABLE usuarioEvento (
  idUsuarioEvento BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idUsuario       BIGINT UNSIGNED         NOT NULL,
  idEvento        BIGINT UNSIGNED         NOT NULL,
  principal       ENUM('S','N')           NOT NULL DEFAULT 'N',
  tipoAval        ENUM('director_programa','director_docencia') NULL,
  avalPDF         VARCHAR(255)            NULL,
  CONSTRAINT fk_ue_usuario FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ue_evento FOREIGN KEY (idEvento) REFERENCES evento(idEvento)
    ON UPDATE CASCADE ON DELETE CASCADE
  -- Reglas de negocio (pendiente con triggers):
  -- 1) Solo roles docente/estudiante.
  -- 2) Un 'principal'='S' por idEvento.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- EVENTOINSTALACION (PK compuesta)
-- =========================================================
CREATE TABLE eventoInstalacion (
  idEvento      BIGINT UNSIGNED NOT NULL,
  idInstalacion BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (idEvento, idInstalacion),
  CONSTRAINT fk_ei_evento      FOREIGN KEY (idEvento)      REFERENCES evento(idEvento)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ei_instalacion FOREIGN KEY (idInstalacion) REFERENCES instalacion(idInstalacion)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- EVENTO ORGANIZACION
-- =========================================================
CREATE TABLE eventoOrganizacion (
  idEventoOrganizacion BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idEvento        BIGINT UNSIGNED         NOT NULL,
  idOrganizacion  BIGINT UNSIGNED         NOT NULL,
  certificadoPDF  VARCHAR(255)            NULL,
  participante    VARCHAR(120)            NOT NULL,
  esRepresentanteLegal BOOLEAN            NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_eo_evento       FOREIGN KEY (idEvento)       REFERENCES evento(idEvento)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_eo_organizacion FOREIGN KEY (idOrganizacion) REFERENCES organizacion(idOrganizacion)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- EVALUACION
-- =========================================================
CREATE TABLE evaluacion (
  idEvaluacion   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idEvento       BIGINT UNSIGNED         NOT NULL,
  comentarios    TEXT                    NULL,
  estado         ENUM('aprobado','rechazado') NOT NULL,
  actaPDF        VARCHAR(255)            NULL,
  fechaRevision  TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_eval_evento FOREIGN KEY (idEvento) REFERENCES evento(idEvento)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- NOTIFICACION
-- =========================================================
CREATE TABLE notificacion (
  idNotificacion   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idEvaluacion     BIGINT UNSIGNED         NOT NULL,
  tipoNotificacion ENUM('aprobado','rechazado') NOT NULL,
  fechaEnvio       TIMESTAMP NULL DEFAULT NULL,
  justificacion    TEXT                    NULL,
  urlPDF           VARCHAR(255)            NULL,
  usuarioReceptor  BIGINT UNSIGNED         NOT NULL,
  CONSTRAINT fk_not_eval FOREIGN KEY (idEvaluacion)    REFERENCES evaluacion(idEvaluacion)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_not_usuario FOREIGN KEY (usuarioReceptor) REFERENCES usuario(idUsuario)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ====== VISTAS ÚTILES (opcionales de apoyo a 2da entrega) ======
CREATE OR REPLACE VIEW v_eventos_detalle AS
SELECT e.idEvento, e.nombre, e.fechaInicio, e.fechaFin, e.categoria, e.estado,
       u.idUsuario AS idOrganizador, u.nombre AS organizador, i.nombre AS instalacion
FROM evento e
JOIN usuario u ON u.idUsuario = e.idOrganizador
JOIN instalacion i ON i.idInstalacion = e.idInstalacion;

CREATE OR REPLACE VIEW v_eventos_pendientes AS
SELECT * FROM evento WHERE estado IN ('registrado','enRevision');
