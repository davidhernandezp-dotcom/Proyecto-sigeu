# app/models/evaluacion.py
from sqlalchemy import BigInteger, String, Text, TIMESTAMP, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Evaluacion(Base):
    __tablename__ = "evaluacion"
    idEvaluacion: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    idEvento: Mapped[int] = mapped_column(BigInteger, ForeignKey("evento.idEvento", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    comentarios: Mapped[str | None] = mapped_column(Text, nullable=True)
    estado: Mapped[str] = mapped_column(Enum('aprobado','rechazado', name="eval_estado"), nullable=False)
    actaPDF: Mapped[str | None] = mapped_column(String(255), nullable=True)
    fechaRevision: Mapped[str | None] = mapped_column(TIMESTAMP(timezone=False), nullable=True)
