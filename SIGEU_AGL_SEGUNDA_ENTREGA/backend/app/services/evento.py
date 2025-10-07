# app/services/evento.py
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from app.schemas.evento import EventoCrear, EventoActualizar
from app.crud import evento as crud
from app.models.evento import Evento


# ---------- CREATE ----------
async def crear(session: AsyncSession, payload: EventoCrear) -> Evento:
    # usa alias para que las claves coincidan con el ORM (idOrganizador, fechaInicio, ...)
    data: Dict[str, Any] = payload.model_dump(by_alias=True, exclude_none=True)
    # por si el cliente no envía estado
    data.setdefault("estado", "registrado")
    try:
        obj = await crud.crear(session, data)
        return obj
    except IntegrityError as e:
        await session.rollback()
        # FK/UNIQUE/CHK → 409 (o 400 según prefieras)
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Violación de integridad al crear evento: {str(e.orig)}",
        )


# ---------- READ ----------
async def listar(session: AsyncSession) -> List[Evento]:
    objetos = await crud.listar(session)
    return objetos


async def obtener(session: AsyncSession, id_evento: int) -> Evento:
    obj = await crud.obtener(session, id_evento)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evento no encontrado")
    return obj


# ---------- UPDATE ----------
async def actualizar(session: AsyncSession, id_evento: int, payload: EventoActualizar) -> Evento:
    # usa alias + exclude_unset para parches parciales
    cambios: Dict[str, Any] = payload.model_dump(by_alias=True, exclude_unset=True, exclude_none=True)
    try:
        obj = await crud.actualizar(session, id_evento, cambios)
        if not obj:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evento no encontrado")
        return obj
    except IntegrityError as e:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Violación de integridad al actualizar evento: {str(e.orig)}",
        )


# ---------- DELETE ----------
async def eliminar(session: AsyncSession, id_evento: int) -> None:
    ok = await crud.eliminar(session, id_evento)
    if not ok:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evento no encontrado")
