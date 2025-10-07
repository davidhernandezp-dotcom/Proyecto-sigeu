# app/models/evento_organizacion.py
from sqlalchemy import BigInteger, String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class EventoOrganizacion(Base):
    __tablename__ = "eventoOrganizacion"
    idEventoOrganizacion: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    idEvento: Mapped[int] = mapped_column(BigInteger, ForeignKey("evento.idEvento", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    idOrganizacion: Mapped[int] = mapped_column(BigInteger, ForeignKey("organizacion.idOrganizacion", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    certificadoPDF: Mapped[str | None] = mapped_column(String(255), nullable=True)
    participante: Mapped[str] = mapped_column(String(120), nullable=False)
    esRepresentanteLegal: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
