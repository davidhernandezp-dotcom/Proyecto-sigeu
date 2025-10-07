# antes:
# from sqlalchemy.orm import Mapped, mapped_column
# después:
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime
from sqlalchemy import String, Integer, Enum, DateTime, ForeignKey
from app.models.base import Base

class Evento(Base):
    __tablename__ = "evento"
    idEvento: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(180))
    descripcion: Mapped[str | None] = mapped_column(String(280), nullable=True)
    idOrganizador: Mapped[int] = mapped_column(Integer, ForeignKey("usuario.idUsuario"))
    idInstalacion: Mapped[int] = mapped_column(Integer, ForeignKey("instalacion.idInstalacion"))
    fechaInicio: Mapped[datetime] = mapped_column(DateTime)
    fechaFin: Mapped[datetime] = mapped_column(DateTime)
    categoria: Mapped[str] = mapped_column(Enum("academico","ludico", name="categoria_evento"))
    estado: Mapped[str] = mapped_column(Enum("registrado","enRevision","aprobado","rechazado", name="estado_evento"), default="registrado")
    rutaAvalPDF: Mapped[str | None] = mapped_column(String(200), nullable=True)

    # NUEVO AJSUTE: backref hacia la tabla puente usuarioEvento
    usuario_eventos = relationship(
        "UsuarioEvento",
        back_populates="evento",
        cascade="all, delete-orphan"
    )
