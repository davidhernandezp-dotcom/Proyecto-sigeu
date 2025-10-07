from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Integer, Enum
from app.models.base import Base

class Instalacion(Base):
    __tablename__ = "instalacion"
    idInstalacion: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(80))
    tipo: Mapped[str] = mapped_column(Enum("salon","auditorio","laboratorio","cancha", name="tipo_instalacion"))
    capacidad: Mapped[int] = mapped_column(Integer)
    ubicacion: Mapped[str] = mapped_column(String(120))
