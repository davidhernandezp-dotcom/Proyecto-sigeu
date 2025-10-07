# app/schemas/evento.py
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field, ConfigDict, model_validator, AliasChoices


Categoria = Literal["academico", "ludico"]
EstadoEvento = Literal["registrado", "enRevision", "aprobado", "rechazado"]

class EventoBase(BaseModel):
    # nombres simples (sin alias)
    nombre: str = Field(min_length=3, max_length=180)
    descripcion: Optional[str] = None
    categoria: Categoria

    # aceptar snake o camel en ENTRADA; serializar en camel
    id_organizador: int = Field(
        validation_alias=AliasChoices("idOrganizador", "id_organizador"),
        serialization_alias="idOrganizador",
    )
    id_instalacion: int = Field(
        validation_alias=AliasChoices("idInstalacion", "id_instalacion"),
        serialization_alias="idInstalacion",
    )
    fecha_inicio: datetime = Field(
        validation_alias=AliasChoices("fechaInicio", "fecha_inicio"),
        serialization_alias="fechaInicio",
    )
    fecha_fin: datetime = Field(
        validation_alias=AliasChoices("fechaFin", "fecha_fin"),
        serialization_alias="fechaFin",
    )
    ruta_aval_pdf: str = Field(
        validation_alias=AliasChoices("rutaAvalPDF", "ruta_aval_pdf"),
        serialization_alias="rutaAvalPDF",
    )

    # Config: permitir poblar por nombre, serializar con alias, ignorar extras
    model_config = ConfigDict(
        populate_by_name=True,
        from_attributes=True,
        extra="ignore",
    )

    # regla: fecha_fin >= fecha_inicio
    @model_validator(mode="after")
    def _validar_rango_fechas(self):
        if self.fecha_fin < self.fecha_inicio:
            raise ValueError("fechaFin debe ser mayor o igual a fechaInicio")
        return self

class EventoCrear(EventoBase):
    # si no envían estado, por defecto 'registrado'
    estado: Optional[EstadoEvento] = "registrado"

class EventoActualizar(BaseModel):
    nombre: Optional[str] = Field(default=None, min_length=3, max_length=180)
    descripcion: Optional[str] = None
    categoria: Optional[Categoria] = None

    id_instalacion: Optional[int] = Field(
        default=None,
        validation_alias=AliasChoices("idInstalacion", "id_instalacion"),
        serialization_alias="idInstalacion",
    )
    fecha_inicio: Optional[datetime] = Field(
        default=None,
        validation_alias=AliasChoices("fechaInicio", "fecha_inicio"),
        serialization_alias="fechaInicio",
    )
    fecha_fin: Optional[datetime] = Field(
        default=None,
        validation_alias=AliasChoices("fechaFin", "fecha_fin"),
        serialization_alias="fechaFin",
    )
    ruta_aval_pdf: Optional[str] = Field(
        default=None,
        validation_alias=AliasChoices("rutaAvalPDF", "ruta_aval_pdf"),
        serialization_alias="rutaAvalPDF",
    )
    estado: Optional[EstadoEvento] = None

    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    @model_validator(mode="after")
    def _validar_rango_fechas(self):
        if self.fecha_inicio and self.fecha_fin and self.fecha_fin < self.fecha_inicio:
            raise ValueError("fechaFin debe ser mayor o igual a fechaInicio")
        return self

class EventoOut(EventoBase):
    # Lee de 'idEvento' (ORM) o 'id_evento' y serializa como 'idEvento'
    id_evento: int = Field(
        validation_alias=AliasChoices("idEvento", "id_evento"),
        serialization_alias="idEvento",
    )
    estado: EstadoEvento
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)