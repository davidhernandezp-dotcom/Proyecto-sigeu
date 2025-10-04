USE uao_eventos;

DELIMITER //
CREATE TRIGGER trg_credencial_unica_activa
BEFORE INSERT ON credenciales
FOR EACH ROW
BEGIN
  IF NEW.estado='activa' THEN
    UPDATE credenciales SET estado='inactiva' WHERE idUsuario=NEW.idUsuario;
  END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_revision_post_insert
AFTER INSERT ON revision
FOR EACH ROW
BEGIN
  UPDATE evento SET estado=NEW.estado WHERE idEvento=NEW.idEvento;

  INSERT INTO notificacion (idRevision, tipoNotificacion, usuarioReceptor, justificacion, urlPDF)
  SELECT NEW.idRevision, NEW.estado, e.idOrganizador, NEW.comentarios, NEW.actaPDF
  FROM evento e WHERE e.idEvento=NEW.idEvento;

  INSERT INTO log_auditoria (entidad, entidad_id, accion, usuario_id, detalle)
  SELECT 'revision', NEW.idRevision, 'INSERT', sa.idUsuario,
         JSON_OBJECT('evento', NEW.idEvento, 'estado', NEW.estado, 'comentarios', NEW.comentarios)
  FROM secretariaAcademica sa
  WHERE sa.idSecretaria=NEW.idSecretariaAcademica;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION fn_existe_solapamiento(p_instalacion BIGINT, p_ini DATETIME, p_fin DATETIME) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE cnt INT;
  SELECT COUNT(*) INTO cnt FROM evento
  WHERE idInstalacion = p_instalacion
    AND fechaInicio < p_fin AND p_ini < fechaFin;
  RETURN cnt > 0;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_crear_evento(
  IN p_nombre VARCHAR(180), IN p_descripcion TEXT,
  IN p_fechaInicio DATETIME, IN p_fechaFin DATETIME,
  IN p_categoria VARCHAR(10),
  IN p_idOrganizador BIGINT, IN p_idInstalacion BIGINT,
  IN p_rutaAvalPDF VARCHAR(255)
)
BEGIN
  IF p_fechaFin < p_fechaInicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='fechaFin no puede ser anterior a fechaInicio';
  END IF;
  IF fn_existe_solapamiento(p_idInstalacion, p_fechaInicio, p_fechaFin) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Existe solapamiento en la misma instalación';
  END IF;
  INSERT INTO evento (nombre, descripcion, fechaInicio, fechaFin, categoria, idOrganizador, idInstalacion, rutaAvalPDF)
  VALUES (p_nombre, p_descripcion, p_fechaInicio, p_fechaFin, p_categoria, p_idOrganizador, p_idInstalacion, p_rutaAvalPDF);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_evento(
  IN p_idEvento BIGINT,
  IN p_nombre VARCHAR(180), IN p_descripcion TEXT,
  IN p_fechaInicio DATETIME, IN p_fechaFin DATETIME,
  IN p_categoria VARCHAR(10),
  IN p_idInstalacion BIGINT, IN p_rutaAvalPDF VARCHAR(255)
)
BEGIN
  IF p_fechaFin < p_fechaInicio THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='fechaFin no puede ser anterior a fechaInicio';
  END IF;
  IF fn_existe_solapamiento(p_idInstalacion, p_fechaInicio, p_fechaFin) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Existe solapamiento en la misma instalación';
  END IF;
  UPDATE evento
    SET nombre=p_nombre, descripcion=p_descripcion, fechaInicio=p_fechaInicio,
        fechaFin=p_fechaFin, categoria=p_categoria, idInstalacion=p_idInstalacion, rutaAvalPDF=p_rutaAvalPDF
  WHERE idEvento=p_idEvento;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_evento(IN p_idEvento BIGINT, IN p_usuario BIGINT)
BEGIN
  INSERT INTO log_auditoria(entidad, entidad_id, accion, usuario_id, detalle)
  VALUES ('evento', p_idEvento, 'DELETE', p_usuario, JSON_OBJECT('motivo','eliminación desde SP'));
  DELETE FROM evento WHERE idEvento=p_idEvento;
END//
DELIMITER ;
