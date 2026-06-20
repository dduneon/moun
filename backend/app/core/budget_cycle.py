from __future__ import annotations

import calendar
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle
from app.models.user import User


def _cycle_bounds(ref_date: date, salary_day: int) -> tuple[date, date, str]:
    """salary_day 기준 사이클 경계 계산.
    예) salary_day=21: 전월 21일 ~ 당월 20일
    salary_day=1: 당월 1일 ~ 당월 말일
    """
    d = salary_day
    if d <= 1:
        # 1일 기준 = 달력 월
        last = calendar.monthrange(ref_date.year, ref_date.month)[1]
        start = ref_date.replace(day=1)
        end = ref_date.replace(day=last)
        label = f"{ref_date.year}년 {ref_date.month}월"
        return start, end, label

    # ref_date가 d일 이상이면 이번 달 d일이 사이클 시작
    if ref_date.day >= d:
        start = ref_date.replace(day=d)
        # end = 다음 달 d-1일
        if ref_date.month == 12:
            end = date(ref_date.year + 1, 1, d - 1)
        else:
            end = date(ref_date.year, ref_date.month + 1, d - 1)
        label = f"{ref_date.year}년 {ref_date.month}월 ({d}일 기준)"
    else:
        # ref_date가 d일 미만이면 전월 d일이 사이클 시작
        if ref_date.month == 1:
            start = date(ref_date.year - 1, 12, d)
        else:
            start = date(ref_date.year, ref_date.month - 1, d)
        end = ref_date.replace(day=d - 1)
        prev_month = start.month
        prev_year = start.year
        label = f"{prev_year}년 {prev_month}월 ({d}일 기준)"

    return start, end, label


def get_cycle_for_date(db: Session, user_id: int, target: date) -> BudgetCycle:
    """target 날짜가 속하는 BudgetCycle 반환. 없으면 현재 salary_day 기준으로 생성."""
    user = db.scalar(select(User).where(User.id == user_id))
    salary_day = user.salary_day if user else 1

    start, end, label = _cycle_bounds(target, salary_day)

    # 정확히 같은 start_date 사이클 먼저 탐색
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
    )
    db.add(cycle)
    db.flush()
    return cycle


def get_or_create_current_cycle(db: Session, user_id: int) -> BudgetCycle:
    return get_cycle_for_date(db, user_id, date.today())
