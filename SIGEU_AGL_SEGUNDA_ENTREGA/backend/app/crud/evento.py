# app/crud/evento.py
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from app.models.evento import Evento


# CREATE
async def crear(session: AsyncSession, data: Dict[str, Any]) -> Evento:
    """
    data debe venir con claves que el ORM entiende (by_alias=True en el service),
    p. ej.: idOrganizador, idInstalacion, fechaInicio, fechaFin, rutaAvalPDF, estado, categoria, nombre, descripcion
    """
    obj = Evento(**data)
    session.add(obj)
    await session.commit()
    await session.refresh(obj)
    return obj


# READ - list
async def listar(session: AsyncSession) -> List[Evento]:
    result = await session.execute(
        select(Evento).order_by(Evento.idEvento.desc())
    )
    return list(result.scalars().all())


# READ - by id
async def obtener(session: AsyncSession, id_evento: int) -> Optional[Evento]:
    obj = await session.get(Evento, id_evento)
    return obj


# UPDATE (parcial)
async def actualizar(session: AsyncSession, id_evento: int, cambios: Dict[str, Any]) -> Optional[Evento]:
    obj = await session.get(Evento, id_evento)
    if not obj:
        return None

    # aplica cambios en atributos válidos
    for k, v in cambios.items():
        # protección mínima: ignora claves desconocidas
        if hasattr(obj, k):
            setattr(obj, k, v)

    await session.commit()
    await session.refresh(obj)
    return obj


# DELETE
async def eliminar(session: AsyncSession, id_evento: int) -> bool:
    obj = await session.get(Evento, id_evento)
    if not obj:
        return False

    await session.delete(obj)
    await session.commit()
    return True
