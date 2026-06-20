from fastapi import APIRouter, HTTPException
from sqlalchemy import select

from app.core.budget_calculator import get_available_budget
from app.core.budget_cycle import get_or_create_current_cycle
from app.core.deps import DbDep, UserDep
from app.models.budget_cycle import BudgetCycle
from app.schemas.budget import AvailableBudget
from app.schemas.common import BudgetCyclePatch, BudgetCycleResponse

router = APIRouter(prefix="/budget-cycles", tags=["budget-cycles"])


def _get_or_404(db, user_id: int, cycle_id: int) -> BudgetCycle:
    cycle = db.scalar(
        select(BudgetCycle).where(BudgetCycle.id == cycle_id, BudgetCycle.user_id == user_id)
    )
    if not cycle:
        raise HTTPException(status_code=404, detail="Not found")
    return cycle


@router.get("/current", response_model=BudgetCycleResponse)
def current_cycle(db: DbDep, user: UserDep):
    return get_or_create_current_cycle(db, user.id)


@router.get("", response_model=list[BudgetCycleResponse])
def list_cycles(db: DbDep, user: UserDep):
    return db.scalars(
        select(BudgetCycle).where(BudgetCycle.user_id == user.id).order_by(BudgetCycle.start_date.desc())
    ).all()


@router.get("/{cycle_id}", response_model=BudgetCycleResponse)
def get_cycle(cycle_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, cycle_id)


@router.patch("/{cycle_id}", response_model=BudgetCycleResponse)
def patch_cycle(cycle_id: int, body: BudgetCyclePatch, db: DbDep, user: UserDep):
    cycle = _get_or_404(db, user.id, cycle_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(cycle, field, value)
    db.commit()
    db.refresh(cycle)
    return cycle


@router.get("/{cycle_id}/budget", response_model=AvailableBudget)
def cycle_budget(cycle_id: int, db: DbDep, user: UserDep):
    _get_or_404(db, user.id, cycle_id)
    return get_available_budget(db, user.id, cycle_id)
