from __future__ import annotations

import calendar
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle

CYCLE_START_DAY = 21  # 매월 21일 시작


def _cycle_bounds(ref_date: date) -> tuple[date, date, str]:
    """ref_date가 속하는 사이클의 start/end/label을 반환."""
    if ref_date.day >= CYCLE_START_DAY:
        start = ref_date.replace(day=CYCLE_START_DAY)
        # 다음달 20일
        if ref_date.month == 12:
            end = date(ref_date.year + 1, 1, 20)
        else:
            end = date(ref_date.year, ref_date.month + 1, 20)
        label = f"{ref_date.year}년 {ref_date.month}월"
    else:
        # 이달 1~20일 → 전달 21일 시작
        if ref_date.month == 1:
            start = date(ref_date.year - 1, 12, CYCLE_START_DAY)
        else:
            start = date(ref_date.year, ref_date.month - 1, CYCLE_START_DAY)
        end = ref_date.replace(day=20)
        # label은 "전달 기준" 사이클명
        prev_month = ref_date.month - 1 or 12
        prev_year = ref_date.year if ref_date.month > 1 else ref_date.year - 1
        label = f"{prev_year}년 {prev_month}월"

    return start, end, label


def get_cycle_for_date(db: Session, target: date) -> BudgetCycle:
    """target 날짜가 속하는 BudgetCycle 반환. 없으면 생성."""
    start, end, label = _cycle_bounds(target)

    cycle = db.scalar(
        select(BudgetCycle).where(BudgetCycle.start_date == start)
    )
    if cycle:
        return cycle

    cycle = BudgetCycle(
        start_date=start,
        end_date=end,
        label=label,
        salary_expected=0,
    )
    db.add(cycle)
    db.flush()
    return cycle


def get_or_create_current_cycle(db: Session) -> BudgetCycle:
    """오늘 날짜 기준 현재 BudgetCycle 반환."""
    return get_cycle_for_date(db, date.today())
