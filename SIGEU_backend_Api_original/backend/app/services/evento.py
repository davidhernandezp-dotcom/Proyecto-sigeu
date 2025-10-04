from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException
from app.crud import evento as crud
from app.schemas.evento import EventoCrear, EventoActualizar

def _validar_fechas(fi: datetime, ff: datetime):
    if ff < fi:
        raise HTTPException(status_code=400, detail="fecha_fin no puede ser anterior a fecha_inicio")

async def crear(session: AsyncSession, payload: EventoCrear):
    _validar_fechas(payload.fecha_inicio, payload.fecha_fin)
    obj = await crud.crear(session, payload.model_dump())
    await session.commit()
    await session.refresh(obj)
    return obj

async def obtener(session: AsyncSession, id_evento: int):
    obj = await crud.obtener(session, id_evento)
    if not obj:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    return obj

async def listar(session: AsyncSession, **filtros):
    return await crud.listar(session, **filtros)

async def actualizar(session: AsyncSession, id_evento: int, payload: EventoActualizar):
    data = {k: v for k, v in payload.model_dump(exclude_unset=True).items()}
    if 'fecha_inicio' in data or 'fecha_fin' in data:
        actual = await obtener(session, id_evento)
        fi = data.get('fecha_inicio', actual.fecha_inicio)
        ff = data.get('fecha_fin', actual.fecha_fin)
        _validar_fechas(fi, ff)
    obj = await crud.actualizar(session, id_evento, data)
    if not obj:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    await session.commit()
    await session.refresh(obj)
    return obj

async def eliminar(session: AsyncSession, id_evento: int):
    ok = await crud.eliminar(session, id_evento)
    if not ok:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    await session.commit()
