from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal

Categoria = Literal["academico","ludico"]
EstadoEvento = Literal["pendiente","aprobado","rechazado"]

class EventoBase(BaseModel):
    nombre: str = Field(min_length=3, max_length=180)
    descripcion: Optional[str] = None
    id_organizador: int
    id_instalacion: int
    fecha_inicio: datetime
    fecha_fin: datetime
    categoria: Categoria
    ruta_aval_pdf: str

class EventoCrear(EventoBase):
    pass

class EventoActualizar(BaseModel):
    nombre: Optional[str] = Field(default=None, min_length=3, max_length=180)
    descripcion: Optional[str] = None
    id_instalacion: Optional[int] = None
    fecha_inicio: Optional[datetime] = None
    fecha_fin: Optional[datetime] = None
    categoria: Optional[Categoria] = None
    ruta_aval_pdf: Optional[str] = None
    estado: Optional[EstadoEvento] = None

class EventoOut(EventoBase):
    model_config = ConfigDict(from_attributes=True)
    id_evento: int
    estado: EstadoEvento
