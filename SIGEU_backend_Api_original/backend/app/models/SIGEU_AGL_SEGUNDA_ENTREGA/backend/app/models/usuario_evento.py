# app/models/usuario_evento.py
from sqlalchemy import BigInteger, String, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class UsuarioEvento(Base):
    __tablename__ = "usuarioEvento"
    idUsuarioEvento: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    idUsuario: Mapped[int] = mapped_column(BigInteger, ForeignKey("usuario.idUsuario", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    idEvento: Mapped[int] = mapped_column(BigInteger, ForeignKey("evento.idEvento", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    principal: Mapped[str] = mapped_column(Enum('S','N', name="ue_principal"), nullable=False)
    tipoAval: Mapped[str | None] = mapped_column(Enum('director_programa','director_docencia', name="ue_tipo_aval"), nullable=True)
    avalPDF: Mapped[str | None] = mapped_column(String(255), nullable=True)


    # Backrefs que esta alienados con los ajustes hechos en Usuario y Evento
 #   usuario = relationship("Usuario", back_populates="usuario_eventos")
  #  evento  = relationship("Evento",  back_populates="usuario_eventos")
