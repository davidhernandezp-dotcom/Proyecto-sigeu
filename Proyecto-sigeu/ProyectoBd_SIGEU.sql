
CREATE TABLE `evento` (
    `idEvento` INT NOT NULL,
    `idInstalacion` INT NOT NULL,
    `nombre` VARCHAR(100) NOT NULL,
    `fechaInicio` DATE NOT NULL,
    `fechaFin` DATE NOT NULL,
    `avalPDF` INT NOT NULL,
    `estado` ENUM('pendiente', 'aprobado', 'rechazado') NOT NULL,
    `categoria` ENUM('academico', 'ludico') NOT NULL,
    `tipo` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`idEvento`),
    UNIQUE (`nombre`, `fechaInicio`, `fechaFin`) -- un mismo evento no se repite en mismas fechas
);

CREATE TABLE `unidadAcademica` (
    `idUnidad` INT NOT NULL,
    `nombre` VARCHAR(100) NOT NULL,
    `tipo` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`idUnidad`),
    UNIQUE (`nombre`) -- cada unidad debe tener nombre único
);

CREATE TABLE `eventoUnidad` (
    `idEventoUnidad` INT NOT NULL,
    `idEvento` INT NOT NULL,
    `idUnidad` INT NOT NULL,
    PRIMARY KEY (`idEventoUnidad`),
    CONSTRAINT fk_eventoUnidad_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`),
    CONSTRAINT fk_eventoUnidad_unidad FOREIGN KEY (`idUnidad`) REFERENCES `unidadAcademica`(`idUnidad`),
    UNIQUE (`idEvento`, `idUnidad`) -- evitar duplicar la misma relación evento-unidad
);

CREATE TABLE `organizacionExterna` (
    `idOrganizacion` INT NOT NULL,
    `nombre` VARCHAR(50) NOT NULL,
    `representanteLegal` VARCHAR(50) NOT NULL,
    `registrado` ENUM('si', 'no') NOT NULL,
    `telefono` VARCHAR(20) NOT NULL,
    `ubicacion` VARCHAR(50) NOT NULL,
    `calle` VARCHAR(50) NOT NULL,
    `ciudad` VARCHAR(50) NOT NULL,
    `codigoPostal` VARCHAR(10) NOT NULL,
    `sectorEconomico` VARCHAR(50) NOT NULL,
    `actividadPrincipal` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`idOrganizacion`),
    UNIQUE (`nombre`) -- evitar organizaciones duplicadas
);

CREATE TABLE `participacion` (
    `idParticipacion` INT NOT NULL,
    `idEvento` INT NOT NULL,
    `idOrganizacion` INT NOT NULL,
    `certificadoPDF` ENUM('si', 'no') NOT NULL,
    PRIMARY KEY (`idParticipacion`),
    CONSTRAINT fk_participacion_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`),
    CONSTRAINT fk_participacion_org FOREIGN KEY (`idOrganizacion`) REFERENCES `organizacionExterna`(`idOrganizacion`),
    UNIQUE (`idEvento`, `idOrganizacion`) -- una org no se repite dos veces en el mismo evento
);

CREATE TABLE `instalacion` (
    `idInstalacion` INT NOT NULL,
    `nombre` VARCHAR(100) NOT NULL,
    `tipo` ENUM('salon', 'laboratorio', 'auditorio') NOT NULL,
    `capacidad` INT NOT NULL,
    `ubicacion` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`idInstalacion`),
    UNIQUE (`nombre`, `ubicacion`) -- no repetir instalación con mismo nombre en misma sede
);

CREATE TABLE `seRealizaEn` (
    `idRealizacion` INT NOT NULL,
    `idEvento` INT NOT NULL,
    `idInstalacion` INT NOT NULL,
    `fechaInicio` DATE NOT NULL,
    `fechaFin` DATE NOT NULL,
    PRIMARY KEY (`idRealizacion`),
    CONSTRAINT fk_realiza_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`),
    CONSTRAINT fk_realiza_instalacion FOREIGN KEY (`idInstalacion`) REFERENCES `instalacion`(`idInstalacion`),
    UNIQUE (`idEvento`, `idInstalacion`, `fechaInicio`) -- evitar duplicados
);

CREATE TABLE `usuario` (
    `idUsuario` INT NOT NULL,
    `nombre` VARCHAR(100) NOT NULL,
    `contrasena` VARCHAR(50) NOT NULL,
    `correo` VARCHAR(50) NOT NULL,
    `rol` ENUM('docente', 'estudiante', 'secretarioAcademico') NOT NULL,
    PRIMARY KEY (`idUsuario`),
    UNIQUE (`correo`) -- cada usuario debe tener un correo único
);

CREATE TABLE `encargado` (
    `idEncargado` INT NOT NULL,
    `idUsuario` INT NOT NULL,
    `idEvento` INT NOT NULL,
    PRIMARY KEY (`idEncargado`),
    CONSTRAINT fk_encargado_usuario FOREIGN KEY (`idUsuario`) REFERENCES `usuario`(`idUsuario`),
    CONSTRAINT fk_encargado_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`),
    UNIQUE (`idUsuario`, `idEvento`) -- un usuario no se repite dos veces como encargado del mismo evento
);

CREATE TABLE `historialContrasena` (
    `idContrasena` INT NOT NULL,
    `idUsuario` INT NOT NULL,
    `fechaInicio` DATE NOT NULL,
    `fechaFin` DATE,
    `vigencia` ENUM('si', 'no') NOT NULL,
    PRIMARY KEY (`idContrasena`),
    CONSTRAINT fk_hist_usuario FOREIGN KEY (`idUsuario`) REFERENCES `usuario`(`idUsuario`)
);

CREATE TABLE `notificacion` (
    `idNotificacion` INT NOT NULL,
    `notificador` VARCHAR(50) NOT NULL,
    `idUsuarioNotificado` INT NOT NULL,
    `tipo` ENUM('aprobado', 'rechazado') NOT NULL,
    `urlPDF` VARCHAR(100) NOT NULL,
    `justificacion` VARCHAR(200) NOT NULL,
    `fechaEnvio` DATE NOT NULL,
    `idEvento` INT NOT NULL,
    PRIMARY KEY (`idNotificacion`),
    CONSTRAINT fk_notif_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`),
    CONSTRAINT fk_notif_usuario FOREIGN KEY (`idUsuarioNotificado`) REFERENCES `usuario`(`idUsuario`)
);

CREATE TABLE `entidadAval` (
    `idAval` INT NOT NULL,
    `urlPDF` VARCHAR(100) NOT NULL,
    `tipoEmisor` VARCHAR(100) NOT NULL,
    `fecha` DATE NOT NULL,
    `idEvento` INT NOT NULL,
    PRIMARY KEY (`idAval`),
    CONSTRAINT fk_aval_evento FOREIGN KEY (`idEvento`) REFERENCES `evento`(`idEvento`)
);

CREATE TABLE `entidadResponsable` (
    `idResponsable` INT NOT NULL,
    `rolEvento` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`idResponsable`)
);

CREATE TABLE `pertenece` (
    `idPertenciente` INT NOT NULL,
    `idUnidad` INT NOT NULL,
    `idResponsable` INT NOT NULL,
    PRIMARY KEY (`idPertenciente`),
    CONSTRAINT fk_pertenece_unidad FOREIGN KEY (`idUnidad`) REFERENCES `unidadAcademica`(`idUnidad`),
    CONSTRAINT fk_pertenece_resp FOREIGN KEY (`idResponsable`) REFERENCES `entidadResponsable`(`idResponsable`),
    UNIQUE (`idUnidad`, `idResponsable`) -- evitar duplicar la misma relación
);
