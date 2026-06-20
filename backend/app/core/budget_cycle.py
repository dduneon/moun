from __future__ import annotations

import calendar
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle


def _cycle_bounds(ref_date: date) -> tuple[date, date, str]:
    """달력 월 기준 (1일 ~ 말일) 사이클."""
    last_day = calendar.monthrange(ref_date.year, ref_date.month)[1]
    start = ref_date.replace(day=1)
    end = ref_date.replace(day=last_day)
    label = f"{ref_date.year}년 {ref_date.month}월"
    return start, end, label


def get_cycle_for_date(db: Session, user_id: int, target: date) -> BudgetCycle:
    """target 날짜가 속하는 BudgetCycle 반환. 없으면 생성."""
    start, end, label = _cycle_bounds(target)

    cycle = db.scalar(
        select(BudgetCycle).where(
            BudgetCycle.user_id == user_id,
            BudgetCycle.start_date == start,
        )
    )
    if cycle:
        return cycle

    cycle = BudgetCycle(
        user_id=user_id,
        start_date=start,
        end_date=end,
        label=label,
        salary_expected=0,
    )
    db.add(cycle)
    db.flush()
    return cycle


def get_or_create_current_cycle(db: Session, user_id: int) -> BudgetCycle:
    return get_cycle_for_date(db, user_id, date.today())
