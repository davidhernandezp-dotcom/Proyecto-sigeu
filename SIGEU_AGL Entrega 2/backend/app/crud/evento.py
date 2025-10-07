from typing import Sequence, Optional
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.evento import Evento

async def crear(session: AsyncSession, data: dict) -> Evento:
    obj = Evento(**data)
    session.add(obj)
    await session.flush()
    return obj

async def obtener(session: AsyncSession, id_evento: int) -> Optional[Evento]:
    res = await session.execute(select(Evento).where(Evento.id_evento == id_evento))
    return res.scalar_one_or_none()

async def listar(session: AsyncSession, q: Optional[str]=None, categoria: Optional[str]=None,
                 estado: Optional[str]=None, fecha_ini: Optional[str]=None, fecha_fin: Optional[str]=None,
                 limit: int=50, offset: int=0) -> Sequence[Evento]:
    stmt = select(Evento)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(Evento.nombre.like(like), Evento.descripcion.like(like)))
    if categoria:
        stmt = stmt.where(Evento.categoria == categoria)
    if estado:
        stmt = stmt.where(Evento.estado == estado)
    if fecha_ini:
        stmt = stmt.where(Evento.fecha_inicio >= fecha_ini)
    if fecha_fin:
        stmt = stmt.where(Evento.fecha_fin <= fecha_fin)
    stmt = stmt.order_by(Evento.fecha_inicio.desc()).limit(limit).offset(offset)
    res = await session.execute(stmt)
    return res.scalars().all()

async def actualizar(session: AsyncSession, id_evento: int, data: dict) -> Optional[Evento]:
    obj = await obtener(session, id_evento)
    if not obj:
        return None
    for k, v in data.items():
        setattr(obj, k, v)
    await session.flush()
    return obj

async def eliminar(session: AsyncSession, id_evento: int) -> bool:
    obj = await obtener(session, id_evento)
    if not obj:
        return False
    await session.delete(obj)
    return True
