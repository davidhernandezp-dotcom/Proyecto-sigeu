# app/api/v1/routes/eventos.py
from fastapi import APIRouter, Depends, status, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.schemas.evento import EventoCrear, EventoActualizar, EventoOut
from app.services import evento as svc

router = APIRouter(prefix="/api/v1", tags=["default"])


# ---------------------------
# POST /api/v1/  -> Crear
# ---------------------------
@router.post(
    "/",
    response_model=EventoOut,
    status_code=status.HTTP_201_CREATED,
    summary="Crear Evento",
)
async def crear_evento(
    payload: EventoCrear,
    session: AsyncSession = Depends(get_session),
):
    """
    Crea un evento. Acepta campos en camelCase (por ejemplo: `fechaInicio`), gracias
    a los alias del schema. Devuelve el `EventoOut` recién creado.
    """
    return await svc.crear(session, payload)


# ---------------------------
# GET /api/v1/  -> Listar
# ---------------------------
@router.get(
    "/",
    response_model=list[EventoOut],
    summary="Listar Eventos",
)
async def listar_eventos(
    session: AsyncSession = Depends(get_session),
):
    """
    Lista los eventos ordenados por `idEvento` descendente.
    """
    return await svc.listar(session)


# ----------------------------------
# GET /api/v1/{id_evento} -> Obtener
# ----------------------------------
@router.get(
    "/{id_evento}",
    response_model=EventoOut,
    summary="Obtener Evento",
)
async def obtener_evento(
    id_evento: int,
    session: AsyncSession = Depends(get_session),
):
    """
    Obtiene un evento por su identificador.
    """
    return await svc.obtener(session, id_evento)


# -------------------------------------
# PUT /api/v1/{id_evento} -> Actualizar
# -------------------------------------
@router.put(
    "/{id_evento}",
    response_model=EventoOut,
    summary="Actualizar Evento",
)
async def actualizar_evento(
    id_evento: int,
    payload: EventoActualizar,
    session: AsyncSession = Depends(get_session),
):
    """
    Actualiza campos del evento. Acepta parches parciales; solo se
    aplican los campos enviados.
    """
    return await svc.actualizar(session, id_evento, payload)


# ------------------------------------
# DELETE /api/v1/{id_evento} -> Borrar
# ------------------------------------
@router.delete(
    "/{id_evento}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar Evento",
)
async def eliminar_evento(
    id_evento: int,
    session: AsyncSession = Depends(get_session),
):
    """
    Elimina un evento. Devuelve 204 si la operación fue exitosa.
    """
    await svc.eliminar(session, id_evento)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
