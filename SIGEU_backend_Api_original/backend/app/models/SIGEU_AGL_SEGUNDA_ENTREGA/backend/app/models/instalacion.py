# app/models/instalacion.py
from sqlalchemy import BigInteger, String, Enum, Integer, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Instalacion(Base):
    __tablename__ = "instalacion"
    idInstalacion: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    tipo: Mapped[str] = mapped_column(Enum('salon','laboratorio','auditorio','otro', name="instalacion_tipo"), nullable=False)
    capacidad: Mapped[int] = mapped_column(Integer, nullable=False)
    ubicacion: Mapped[str] = mapped_column(String(150), nullable=False)
    __table_args__ = (CheckConstraint("capacidad > 0", name="chk_inst_capacidad"),)
