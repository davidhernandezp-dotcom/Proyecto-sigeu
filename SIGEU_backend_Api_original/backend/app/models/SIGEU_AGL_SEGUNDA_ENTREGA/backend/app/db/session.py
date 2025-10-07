# app/db/session.py
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
import os

# .env → DATABASE_URL=mysql+aiomysql://user:password@localhost:3306/uao_eventos
DATABASE_URL = os.getenv("DATABASE_URL", "mysql+aiomysql://user:password@localhost:3306/uao_eventos")

engine = create_async_engine(DATABASE_URL, pool_pre_ping=True, echo=False)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session
