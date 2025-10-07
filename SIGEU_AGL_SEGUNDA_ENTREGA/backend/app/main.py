# app/main.py
from fastapi import FastAPI
from app.api.v1.routes.eventos import router as eventos_router

app = FastAPI(title="SIGEU")
app.include_router(eventos_router)  # 
