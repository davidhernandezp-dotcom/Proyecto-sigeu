# app/models/evento_instalacion.py
from sqlalchemy import BigInteger, ForeignKey, PrimaryKeyConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class EventoInstalacion(Base):
    __tablename__ = "eventoInstalacion"
    idEvento: Mapped[int] = mapped_column(BigInteger, ForeignKey("evento.idEvento", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    idInstalacion: Mapped[int] = mapped_column(BigInteger, ForeignKey("instalacion.idInstalacion", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)
