# app/models/usuario.py
from sqlalchemy import BigInteger, String, Enum
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class Usuario(Base):
    __tablename__ = "usuario"
    idUsuario: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    correo: Mapped[str] = mapped_column(String(150), nullable=False)
    rol: Mapped[str] = mapped_column(Enum('docente','estudiante','secretariaAcademica', name="usuario_rol"), nullable=False)
