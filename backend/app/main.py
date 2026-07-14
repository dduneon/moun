from fastapi import FastAPI

from app.api import (
    auth,
    budget_cycles,
    cards,
    categories,
    fixed_expenses,
    incomes,
    space_budget_cycles,
    space_categories,
    space_fixed_expenses,
    space_incomes,
    space_transactions,
    spaces,
    transactions,
    vouchers,
)
from app.core.config import settings

app = FastAPI(title=settings.APP_NAME, version="0.1.0")

app.include_router(auth.router)
app.include_router(budget_cycles.router)
app.include_router(categories.router)
app.include_router(incomes.router)
app.include_router(fixed_expenses.router)
app.include_router(cards.router)
app.include_router(vouchers.router)
app.include_router(transactions.router)
app.include_router(spaces.router)
app.include_router(space_categories.router)
app.include_router(space_incomes.router)
app.include_router(space_fixed_expenses.router)
app.include_router(space_transactions.router)
app.include_router(space_budget_cycles.router)


@app.get("/health")
async def health():
    return {"app": settings.APP_NAME, "status": "ok"}
