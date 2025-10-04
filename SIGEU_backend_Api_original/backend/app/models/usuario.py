from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer
from app.db import Base

class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario: Mapped[int] = mapped_column("idUsuario", Integer, primary_key=True, autoincrement=True)
