# SIGEU - Entrega 2 (Backend FastAPI + MySQL)

## 1. Estructura del backend (patrón del profesor)
```
app/
  api/v1/routes/eventos.py
  services/evento.py
  crud/evento.py
  models/evento.py
  schemas/evento.py
  db/__init__.py
.env.example
requirements.txt
sql/
  CREAR_DASE_D_ver_2.sql
  insert_uao.sql
  consultas_control.sql
  consultas_avanzadas.sql
  objetos_crud_evento.sql
docs/
  Flujo_SIGEU_Backend.png
```

## 2. Montaje del entorno
```bash
# Python 3.13
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/Mac
# source .venv/bin/activate

pip install -r requirements.txt
```

## 3. Base de datos
```bash
mysql -u root -p < sql/CREAR_DASE_D_ver_2.sql
mysql -u root -p uao_eventos < sql/insert_uao.sql
mysql -u root -p uao_eventos < sql/objetos_crud_evento.sql
```

## 4. Variables de entorno
Copiar `.env.example` a `.env` y ajustar la conexión:
```
DATABASE_URL=mysql+asyncmy://user:password@localhost:3306/uao_eventos
```

## 5. Ejecutar backend
```bash
uvicorn app.main:app --reload
# Swagger: http://127.0.0.1:8000/docs
```

## 6. Endpoints clave (CRUD eventos)
- **POST** `/api/v1/eventos/` → Crea evento (valida fechas y evita solapamientos).
- **GET** `/api/v1/eventos/` → Lista con filtros `q`, `categoria`, `estado`, `fecha_ini`, `fecha_fin`.
- **GET** `/api/v1/eventos/{id}` → Obtiene detalle.
- **PUT** `/api/v1/eventos/{id}` → Actualiza (revalida fechas/solapamiento).
- **DELETE** `/api/v1/eventos/{id}` → Elimina (opcional vía SP con auditoría).

## 7. Pruebas rápidas (Swagger/Postman)
1. **Crear**: En Swagger, probar `POST /api/v1/eventos` con un JSON válido.
2. **Listar**: `GET /api/v1/eventos` y filtrar por `categoria=academico`.
3. **Detalle**: Crear y luego `GET /api/v1/eventos/{id}`.
4. **Actualizar**: `PUT /api/v1/eventos/{id}` cambiando `fecha_fin` o `categoria`.
5. **Eliminar**: `DELETE /api/v1/eventos/{id}` y verificar 204.

## 8. Consultas SQL
- **Control**: `sql/consultas_control.sql`
- **Avanzadas** (toma de decisiones): `sql/consultas_avanzadas.sql`

## 9. Sustentación (guía 15 minutos / 5 integrantes)
- **Intro (1 min)**: contexto UAO, objetivo SIGEU.  
- **Modelo de datos (3 min)**: tablas clave, relaciones, integridad (CHECK/FOREIGN KEYS).  
- **Backend (4 min)**: capas (routes→services→crud→models→db), validaciones y SP/funciones/triggers.  
- **Consultas avanzadas (4 min)**: 4–5 ejemplos y decisiones que habilitan.  
- **Pruebas y demo (3 min)**: CRUD en Swagger/Postman + evidencia de respuestas.
