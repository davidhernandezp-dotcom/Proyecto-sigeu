# antes:
# from sqlalchemy.orm import Mapped, mapped_column
# después:
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Enum, Integer
from app.models.base import Base

class Usuario(Base):
    __tablename__ = "usuario"
    idUsuario: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(100))
    correo: Mapped[str] = mapped_column(String(120), unique=True)
    rol: Mapped[str] = mapped_column(Enum("docente","estudiante","secretariaAcademica", name="rol_usuario"))

    # NUEVO AJUSTE: backref hacia la tabla puente usuarioEvento
    usuario_eventos = relationship("UsuarioEvento", back_populates="usuario")
