from fastapi import FastAPI

from app.api import auth, budget_cycles, cards, categories, fixed_expenses, incomes, transactions
from app.api import settings as settings_api
from app.core.config import settings

app = FastAPI(title=settings.APP_NAME, version="0.1.0")

app.include_router(auth.router)
app.include_router(budget_cycles.router)
app.include_router(categories.router)
app.include_router(incomes.router)
app.include_router(fixed_expenses.router)
app.include_router(cards.router)
app.include_router(transactions.router)
app.include_router(settings_api.router)


@app.get("/health")
async def health():
    return {"app": settings.APP_NAME, "status": "ok"}
