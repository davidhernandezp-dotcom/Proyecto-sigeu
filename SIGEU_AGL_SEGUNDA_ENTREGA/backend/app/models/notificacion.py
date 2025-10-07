# app/models/notificacion.py
from sqlalchemy import BigInteger, String, Text, TIMESTAMP, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Notificacion(Base):
    __tablename__ = "notificacion"
    idNotificacion: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    idEvaluacion: Mapped[int] = mapped_column(BigInteger, ForeignKey("evaluacion.idEvaluacion", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    tipoNotificacion: Mapped[str] = mapped_column(Enum('aprobado','rechazado', name="notif_tipo"), nullable=False)
    fechaEnvio: Mapped[str | None] = mapped_column(TIMESTAMP(timezone=False), nullable=True)
    justificacion: Mapped[str | None] = mapped_column(Text, nullable=True)
    urlPDF: Mapped[str | None] = mapped_column(String(255), nullable=True)
    usuarioReceptor: Mapped[int] = mapped_column(BigInteger, ForeignKey("usuario.idUsuario", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
