# app/models/evento.py
from datetime import datetime
from sqlalchemy import String, Text, Enum, ForeignKey, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.db import Base

class Evento(Base):
    __tablename__ = "evento"

    id_evento: Mapped[int] = mapped_column("idEvento", Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(180), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)

    id_organizador: Mapped[int] = mapped_column(
        "idOrganizador", ForeignKey("usuario.idUsuario"), nullable=False
    )
    id_instalacion: Mapped[int] = mapped_column(
        "idInstalacion", ForeignKey("instalacion.idInstalacion"), nullable=False
    )

    # 👇 Importante: sin comillas y con el import de arriba
    fecha_inicio: Mapped[datetime] = mapped_column("fechaInicio", DateTime, nullable=False)
    fecha_fin:    Mapped[datetime] = mapped_column("fechaFin", DateTime, nullable=False)

    categoria: Mapped[str] = mapped_column(
        Enum("academico", "ludico", name="categoria_enum"), nullable=False
    )
    estado: Mapped[str] = mapped_column(
        Enum("pendiente", "aprobado", "rechazado", name="estado_evento_enum"),
        default="pendiente",
        nullable=False,
    )
    ruta_aval_pdf: Mapped[str] = mapped_column("rutaAvalPDF", String(255), nullable=False)
