from datetime import date

from fastapi import APIRouter

from app.core.budget_cycle import get_current_cycle, get_recent_cycles
from app.core.deps import DbDep, SpaceDep
from app.core.space_budget_calculator import get_space_available_budget
from app.schemas.budget import AvailableBudget, CycleBoundsResponse

router = APIRouter(prefix="/spaces/{space_id}/budget-cycles", tags=["space-budget-cycles"])


@router.get("/current", response_model=CycleBoundsResponse)
def current_space_cycle(space: SpaceDep):
    c = get_current_cycle(space.base_day)
    return CycleBoundsResponse(start_date=c.start, end_date=c.end, label=c.label)


@router.get("", response_model=list[CycleBoundsResponse])
def list_space_cycles(space: SpaceDep, count: int = 6):
    joined = space.created_at.date() if space.created_at else None
    cycles = get_recent_cycles(space.base_day, count, joined_date=joined)
    return [CycleBoundsResponse(start_date=c.start, end_date=c.end, label=c.label) for c in cycles]


@router.get("/current/budget", response_model=AvailableBudget)
def current_space_budget(space: SpaceDep, db: DbDep):
    c = get_current_cycle(space.base_day)
    return get_space_available_budget(db, space.id, c.start, c.end, c.label)


@router.get("/by-date/budget", response_model=AvailableBudget)
def space_budget_by_date(start_date: str, end_date: str, label: str, space: SpaceDep, db: DbDep):
    start = date.fromisoformat(start_date)
    end = date.fromisoformat(end_date)
    return get_space_available_budget(db, space.id, start, end, label)
