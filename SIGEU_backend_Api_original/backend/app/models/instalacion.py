from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer
from app.db import Base

class Instalacion(Base):
    __tablename__ = "instalacion"

    id_instalacion: Mapped[int] = mapped_column("idInstalacion", Integer, primary_key=True, autoincrement=True)
