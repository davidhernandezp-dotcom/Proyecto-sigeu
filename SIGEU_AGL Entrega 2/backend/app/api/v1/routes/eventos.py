from typing import Annotated, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import get_session
from app.schemas.evento import EventoCrear, EventoActualizar, EventoOut
from app.services import evento as svc

router = APIRouter()
SessionDep = Annotated[AsyncSession, Depends(get_session)]

@router.post("/", response_model=EventoOut, status_code=status.HTTP_201_CREATED)
async def crear_evento(payload: EventoCrear, session: SessionDep):
    return await svc.crear(session, payload)

@router.get("/{id_evento}", response_model=EventoOut)
async def obtener_evento(id_evento: int, session: SessionDep):
    return await svc.obtener(session, id_evento)

@router.get("/", response_model=list[EventoOut])
async def listar_eventos(
    session: SessionDep,
    q: Optional[str] = Query(None),
    categoria: Optional[str] = Query(None),
    estado: Optional[str] = Query(None),
    fecha_ini: Optional[str] = Query(None, description="YYYY-MM-DD"),
    fecha_fin: Optional[str] = Query(None, description="YYYY-MM-DD"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    return await svc.listar(session, q=q, categoria=categoria, estado=estado,
                            fecha_ini=fecha_ini, fecha_fin=fecha_fin,
                            limit=limit, offset=offset)

@router.put("/{id_evento}", response_model=EventoOut)
async def actualizar_evento(id_evento: int, payload: EventoActualizar, session: SessionDep):
    return await svc.actualizar(session, id_evento, payload)

@router.delete("/{id_evento}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_evento(id_evento: int, session: SessionDep):
    await svc.eliminar(session, id_evento)
    return None
