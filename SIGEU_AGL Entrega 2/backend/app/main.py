from fastapi import FastAPI
from fastapi.responses import RedirectResponse
import app.models  # asegura que se registren los modelos
from app.api.v1.routes.eventos import router as eventos_router

app = FastAPI(title="SIGEU", version="0.1.0")

@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")

app.include_router(eventos_router, prefix="/api/v1")
