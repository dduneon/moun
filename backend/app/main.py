from fastapi import FastAPI
from app.core.config import settings

app = FastAPI(title=settings.APP_NAME, version="0.1.0")


@app.get("/health")
async def health():
    return {"app": settings.APP_NAME, "status": "ok"}
