# app/models/usuario_evento.py
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Integer, Enum, ForeignKey
from app.models.base import Base

class UsuarioEvento(Base):
    __tablename__ = "usuarioEvento"

    idUsuarioEvento: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    idUsuario: Mapped[int] = mapped_column(Integer, ForeignKey("usuario.idUsuario", ondelete="RESTRICT"), nullable=False)
    idEvento: Mapped[int]  = mapped_column(Integer, ForeignKey("evento.idEvento",  ondelete="CASCADE"),  nullable=False)

    avalPDF: Mapped[str | None] = mapped_column(String(200), nullable=True)
    principal: Mapped[str] = mapped_column(Enum("S","N", name="principal_flag"), default="S", nullable=False)
    tipoAval: Mapped[str | None] = mapped_column(Enum("director_programa","director_docencia", name="tipo_aval"), nullable=True)

    # Backrefs que esta alienados con los ajustes hechos en Usuario y Evento
    usuario = relationship("Usuario", back_populates="usuario_eventos")
    evento  = relationship("Evento",  back_populates="usuario_eventos")
