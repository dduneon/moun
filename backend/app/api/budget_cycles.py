from fastapi import APIRouter

from app.core.budget_calculator import get_available_budget
from app.core.budget_cycle import get_current_cycle, get_recent_cycles
from app.core.deps import DbDep, UserDep
from app.schemas.budget import AvailableBudget, CycleBoundsResponse

router = APIRouter(prefix="/budget-cycles", tags=["budget-cycles"])


@router.get("/current", response_model=CycleBoundsResponse)
def current_cycle(user: UserDep):
    c = get_current_cycle(user.salary_day)
    return CycleBoundsResponse(start_date=c.start, end_date=c.end, label=c.label)


@router.get("", response_model=list[CycleBoundsResponse])
def list_cycles(user: UserDep, count: int = 6):
    cycles = get_recent_cycles(user.salary_day, count)
    return [CycleBoundsResponse(start_date=c.start, end_date=c.end, label=c.label) for c in cycles]


@router.get("/current/budget", response_model=AvailableBudget)
def current_budget(db: DbDep, user: UserDep):
    c = get_current_cycle(user.salary_day)
    return get_available_budget(db, user.id, c.start, c.end, c.label)


@router.get("/by-date/budget", response_model=AvailableBudget)
def budget_by_date(start_date: str, end_date: str, label: str, db: DbDep, user: UserDep):
    from datetime import date
    start = date.fromisoformat(start_date)
    end = date.fromisoformat(end_date)
    return get_available_budget(db, user.id, start, end, label)
