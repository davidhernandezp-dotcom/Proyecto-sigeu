# app/models/evento.py
from sqlalchemy import BigInteger, String, Text, DateTime, Enum, ForeignKey, TIMESTAMP, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Evento(Base):
    __tablename__ = "evento"
    idEvento: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(180), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    fechaInicio: Mapped[DateTime] = mapped_column(DateTime, nullable=False)
    fechaFin: Mapped[DateTime] = mapped_column(DateTime, nullable=False)
    estado: Mapped[str] = mapped_column(Enum('registrado','enRevision','aprobado','rechazado', name="evento_estado"), nullable=False)
    categoria: Mapped[str] = mapped_column(Enum('academico','ludico', name="evento_categoria"), nullable=False)
    idOrganizador: Mapped[int] = mapped_column(BigInteger, ForeignKey("usuario.idUsuario", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    idInstalacion: Mapped[int] = mapped_column(BigInteger, ForeignKey("instalacion.idInstalacion", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    rutaAvalPDF: Mapped[str] = mapped_column(String(255), nullable=False)
    fechaRegistro: Mapped[DateTime | None] = mapped_column(TIMESTAMP(timezone=False), nullable=True)
    __table_args__ = (CheckConstraint("fechaFin >= fechaInicio", name="chk_evento_fechas"),)







    # NUEVO AJSUTE: backref hacia la tabla puente usuarioEvento
 #   usuario_eventos = relationship(
#      "UsuarioEvento",
 #       back_populates="evento",
  #      cascade="all, delete-orphan"
# )
