-- ======================================================================
-- 5_objetos_crud_evento.sql
-- Esquema: uao_eventos
-- Contiene: 3 funciones, 3 vistas y 4 triggers (>=3) con propósito de gestión
-- ======================================================================

USE uao_eventos;

-- =========================================================
-- =====================  FUNCIONES  =======================
-- =========================================================

-- [Función 1]
-- Nombre: fn_dias_restantes_evento
-- ¿Qué es?: Utilitaria de calendario para un evento puntual.
-- ¿Para qué sirve?: Medir cuántos días faltan para el inicio de un evento.
-- Propósito: Apoyar recordatorios, SLAs y priorizar logística.
-- Información que arroja: Entero con días (positivo=por iniciar; negativo=ya pasó).
-- Decisiones: Acelerar avales, reasignar salas, avisos automáticos si < X días.
-- Tablas/relaciones: evento (idEvento -> fechas).
DROP FUNCTION IF EXISTS fn_dias_restantes_evento;
DELIMITER $$
CREATE FUNCTION fn_dias_restantes_evento(p_id BIGINT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE d INT;
  SELECT DATEDIFF(fechaInicio, CURRENT_DATE()) INTO d
  FROM evento
  WHERE idEvento = p_id;
  RETURN d;
END$$
DELIMITER ;

-- [Función 2]
-- Nombre: fn_evento_duracion_horas
-- ¿Qué es?: Utilitaria de esfuerzo operativo.
-- ¿Para qué sirve?: Calcular horas de ocupación por evento.
-- Propósito: Insumo para KPIs de utilización/agenda y costos.
-- Información: Entero con duración en horas (redondeo natural de TIMESTAMPDIFF).
-- Decisiones: Bloques de agenda, personal, limpieza entre eventos.
-- Tablas/relaciones: evento (fechas inicio/fin).
DROP FUNCTION IF EXISTS fn_evento_duracion_horas;
DELIMITER $$
CREATE FUNCTION fn_evento_duracion_horas(p_id BIGINT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE horas INT;
  SELECT TIMESTAMPDIFF(HOUR, fechaInicio, fechaFin)
    INTO horas
  FROM evento
  WHERE idEvento = p_id;
  RETURN horas;
END$$
DELIMITER ;

-- [Función 3]
-- Nombre: fn_horas_instalacion_30d
-- ¿Qué es?: Agregación de uso de una instalación (últimos 30 días).
-- ¿Para qué sirve?: Medir saturación real por espacio.
-- Propósito: Insumo para priorizar ampliaciones/reparaciones o reasignar reservas.
-- Información: Entero con horas sumadas de todos los eventos (incluye instalación por defecto y adicionales).
-- Decisiones: Abrir nuevas salas, limitar cupos, ajustar cronogramas.
-- Tablas/relaciones: evento, eventoInstalacion, instalacion.
DROP FUNCTION IF EXISTS fn_horas_instalacion_30d;
DELIMITER $$
CREATE FUNCTION fn_horas_instalacion_30d(p_inst BIGINT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE total_horas INT;
  SELECT IFNULL(SUM(TIMESTAMPDIFF(HOUR, e.fechaInicio, e.fechaFin)),0) INTO total_horas
  FROM (
    SELECT idEvento, idInstalacion FROM evento
    UNION ALL
    SELECT idEvento, idInstalacion FROM eventoInstalacion
  ) ei
  JOIN evento e ON e.idEvento = ei.idEvento
  WHERE ei.idInstalacion = p_inst
    AND e.fechaInicio >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);
  RETURN total_horas;
END$$
DELIMITER ;



-- =========================================================
-- =======================  VISTAS  ========================
-- =========================================================

-- [Vista 1]
-- Nombre: v_eventos_pendientes
-- ¿Qué es?: Lista de eventos sin decisión final.
-- ¿Para qué sirve?: Controlar backlog y priorizar revisiones.
-- Propósito: Ver rápidamente los casos en 'registrado' o 'enRevision'.
-- Información: Todas las columnas de evento filtradas por estado.
-- Decisiones: Aumentar capacidad de comité, fijar fechas de revisión.
-- Tablas/relaciones: evento (solo).
CREATE OR REPLACE VIEW v_eventos_pendientes AS
SELECT *
FROM evento
WHERE estado IN ('registrado','enRevision');

-- [Vista 2]
-- Nombre: v_evento_x_instalacion
-- ¿Qué es?: Mapa evento ↔ instalación unificado.
-- ¿Para qué sirve?: Cálculos de ocupación, solapamientos y reportes por sala.
-- Propósito: Consolidar instalación por defecto + instalaciones adicionales.
-- Información: idEvento, idInstalacion, nombre de instalación.
-- Decisiones: Reprogramar, dividir eventos, asignar personal por sala.
-- Tablas/relaciones: evento + eventoInstalacion + instalacion.
CREATE OR REPLACE VIEW v_evento_x_instalacion AS
SELECT e.idEvento, e.idInstalacion AS idInstalacion, i.nombre AS instalacion
FROM evento e
JOIN instalacion i ON i.idInstalacion = e.idInstalacion
UNION
SELECT ei.idEvento, ei.idInstalacion, i2.nombre AS instalacion
FROM eventoInstalacion ei
JOIN instalacion i2 ON i2.idInstalacion = ei.idInstalacion;

-- [Vista 3]
-- Nombre: v_conflictos_instalacion
-- ¿Qué es?: Pares de eventos que se solapan en la misma instalación.
-- ¿Para qué sirve?: Anticipar choques y evitar sobreaforo.
-- Propósito: Listar conflictos con detalle (eventos y sala).
-- Información: idInstalacion, instalacion, idEvento1, idEvento2, ventana de choque.
-- Decisiones: Cambiar horario/sala, avisos, políticas de booking.
-- Tablas/relaciones: v_evento_x_instalacion, evento (self-join por sala/tiempo).
CREATE OR REPLACE VIEW v_conflictos_instalacion AS
SELECT 
  a.idInstalacion,
  a.instalacion,
  e1.idEvento  AS idEvento1,
  e2.idEvento  AS idEvento2,
  GREATEST(e1.fechaInicio, e2.fechaInicio) AS choque_inicio,
  LEAST(e1.fechaFin,     e2.fechaFin)      AS choque_fin
FROM v_evento_x_instalacion a
JOIN evento e1 ON e1.idEvento = a.idEvento
JOIN v_evento_x_instalacion b
  ON a.idInstalacion = b.idInstalacion
 AND a.idEvento      < b.idEvento
JOIN evento e2 ON e2.idEvento = b.idEvento
WHERE e1.fechaInicio < e2.fechaFin
  AND e2.fechaInicio < e1.fechaFin;



-- =========================================================
-- ======================  TRIGGERS  =======================
-- =========================================================

-- [Trigger 1]
-- Nombre: trg_ue_check_rol (BEFORE INSERT)
-- ¿Qué es?: Validación de negocio sobre roles permitidos.
-- ¿Para qué sirve?: Impedir que perfiles no válidos se asocien a eventos.
-- Propósito: Garantizar que solo 'docente'/'estudiante' estén en usuarioEvento.
-- Información: Falla con SIGNAL si el rol no es permitido (control de calidad de datos).
-- Decisiones: Mantener integridad del proceso de organización.
-- Tablas/relaciones: usuarioEvento (NEW.idUsuario) → usuario.rol
DROP TRIGGER IF EXISTS trg_ue_check_rol;
DELIMITER $$
CREATE TRIGGER trg_ue_check_rol
BEFORE INSERT ON usuarioEvento
FOR EACH ROW
BEGIN
  DECLARE vrol VARCHAR(30);
  SELECT rol INTO vrol FROM usuario WHERE idUsuario = NEW.idUsuario;
  IF vrol NOT IN ('docente','estudiante') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'usuarioEvento: solo roles docente/estudiante';
  END IF;
END$$
DELIMITER ;

-- [Trigger 2]
-- Nombre: trg_ue_unico_principal_ins (BEFORE INSERT)
-- ¿Qué es?: Regla de unicidad del organizador principal por evento (en altas).
-- ¿Para qué sirve?: Evitar ambigüedad de responsabilidad.
-- Propósito: Permitir solo un principal='S' por idEvento.
-- Información: Falla con SIGNAL si ya existe un principal.
-- Decisiones: Claridad de liderazgo y trazabilidad.
-- Tablas/relaciones: usuarioEvento (conteo por idEvento).
DROP TRIGGER IF EXISTS trg_ue_unico_principal_ins;
DELIMITER $$
CREATE TRIGGER trg_ue_unico_principal_ins
BEFORE INSERT ON usuarioEvento
FOR EACH ROW
BEGIN
  IF NEW.principal = 'S' THEN
    IF (SELECT COUNT(*) FROM usuarioEvento WHERE idEvento = NEW.idEvento AND principal='S') > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'usuarioEvento: ya existe un principal= S para este evento';
    END IF;
  END IF;
END$$
DELIMITER ;

-- [Trigger 3]
-- Nombre: trg_ue_unico_principal_upd (BEFORE UPDATE)
-- ¿Qué es?: Regla de unicidad del organizador principal por evento (en cambios).
-- ¿Para qué sirve?: Evitar que una actualización genere doble principal.
-- Propósito: Mantener la unicidad en updates.
-- Información: Falla con SIGNAL si ya hay un principal distinto al actual.
-- Decisiones: Consistencia del flujo organizativo.
-- Tablas/relaciones: usuarioEvento (conteo por idEvento, excluyendo el propio).
DROP TRIGGER IF EXISTS trg_ue_unico_principal_upd;
DELIMITER $$
CREATE TRIGGER trg_ue_unico_principal_upd
BEFORE UPDATE ON usuarioEvento
FOR EACH ROW
BEGIN
  IF NEW.principal = 'S' AND (OLD.principal <> 'S') THEN
    IF (SELECT COUNT(*) FROM usuarioEvento
        WHERE idEvento = NEW.idEvento
          AND principal='S'
          AND idUsuarioEvento <> OLD.idUsuarioEvento) > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'usuarioEvento: ya existe un principal= S para este evento';
    END IF;
  END IF;
END$$
DELIMITER ;

-- [Trigger 4]
-- Nombre: trg_eval_after_insert (AFTER INSERT)
-- ¿Qué es?: Automatización post-evaluación.
-- ¿Para qué sirve?: Sincronizar estado del evento y generar notificación al organizador.
-- Propósito: Al registrar una evaluación, actualizar evento.estado y crear notificación formal.
-- Información: Inserta en notificacion con datos coherentes al esquema (tipoNotificacion, justificacion, urlPDF, receptor).
-- Decisiones: Trazabilidad y comunicación inmediata del veredicto.
-- Tablas/relaciones: evaluacion NEW → evento (actualiza) → notificacion (INSERT con idOrganizador como receptor).
DROP TRIGGER IF EXISTS trg_eval_after_insert;
DELIMITER $$
CREATE TRIGGER trg_eval_after_insert
AFTER INSERT ON evaluacion
FOR EACH ROW
BEGIN
  -- 1) Actualiza estado del evento
  UPDATE evento
     SET estado = NEW.estado
   WHERE idEvento = NEW.idEvento;

  -- 2) Crea notificación al organizador principal (usamos idOrganizador del evento)
  INSERT INTO notificacion (idEvaluacion, tipoNotificacion, fechaEnvio, justificacion, urlPDF, usuarioReceptor)
  SELECT NEW.idEvaluacion, NEW.estado, NOW(), NEW.comentarios, NEW.actaPDF, e.idOrganizador
  FROM evento e
  WHERE e.idEvento = NEW.idEvento;
END$$
DELIMITER ;

-- (Opcional pero recomendable) Trigger homólogo para updates
DROP TRIGGER IF EXISTS trg_eval_after_update;
DELIMITER $$
CREATE TRIGGER trg_eval_after_update
AFTER UPDATE ON evaluacion
FOR EACH ROW
BEGIN
  UPDATE evento
     SET estado = NEW.estado
   WHERE idEvento = NEW.idEvento;

  INSERT INTO notificacion (idEvaluacion, tipoNotificacion, fechaEnvio, justificacion, urlPDF, usuarioReceptor)
  SELECT NEW.idEvaluacion, NEW.estado, NOW(), NEW.comentarios, NEW.actaPDF, e.idOrganizador
  FROM evento e
  WHERE e.idEvento = NEW.idEvento;
END$$
DELIMITER ;
