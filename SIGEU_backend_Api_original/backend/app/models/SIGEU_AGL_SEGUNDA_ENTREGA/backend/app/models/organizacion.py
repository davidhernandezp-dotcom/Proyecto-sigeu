# app/models/organizacion.py
from sqlalchemy import BigInteger, String
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Organizacion(Base):
    __tablename__ = "organizacion"

    idOrganizacion: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(150), nullable=False)
    representanteLegal: Mapped[str] = mapped_column(String(120), nullable=False)
    actividadPrincipal: Mapped[str] = mapped_column(String(160), nullable=False)
    telefono: Mapped[str] = mapped_column(String(40), nullable=False)
    ubicacion: Mapped[str] = mapped_column(String(150), nullable=False)
    sectorEconomico: Mapped[str] = mapped_column(String(120), nullable=False)
