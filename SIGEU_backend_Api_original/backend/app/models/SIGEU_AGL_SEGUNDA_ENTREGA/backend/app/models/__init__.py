# app/models/__init__.py

from .base import Base

# importa SOLO lo que exista 
from .usuario import Usuario
from .instalacion import Instalacion
from .organizacion import Organizacion
from .evento import Evento
from .usuario_evento import UsuarioEvento
from .evento_instalacion import EventoInstalacion
from .evento_organizacion import EventoOrganizacion
from .evaluacion import Evaluacion
from .notificacion import Notificacion
