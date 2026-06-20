from __future__ import annotations

import calendar
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle
from app.models.user_setting import UserSetting


def _get_salary_day(db: Session, user_id: int) -> int:
    setting = db.scalar(select(UserSetting).where(UserSetting.user_id == user_id))
    return setting.salary_day if setting else 21


def _cycle_bounds(ref_date: date, salary_day: int) -> tuple[date, date, str]:
    """
    ref_date가 속하는 사이클의 (start, end, label)을 반환.

    사이클 구조: salary_day일 ~ 익월 (salary_day - 1)일
    예) salary_day=21: 6/21 ~ 7/20, salary_day=10: 6/10 ~ 7/9
    """
    if ref_date.day >= salary_day:
        start = ref_date.replace(day=salary_day)
        if salary_day == 1:
            # 1일 시작이면 해당 월 말일이 종료일
            end = ref_date.replace(day=calendar.monthrange(ref_date.year, ref_date.month)[1])
            end_label_year, end_label_month = ref_date.year, ref_date.month
        else:
            if ref_date.month == 12:
                end_year, end_month = ref_date.year + 1, 1
            else:
                end_year, end_month = ref_date.year, ref_date.month + 1
            end_day = min(salary_day - 1, calendar.monthrange(end_year, end_month)[1])
            end = date(end_year, end_month, end_day)
        label = f"{ref_date.year}년 {ref_date.month}월"
    else:
        # ref_date.day < salary_day → 전달 salary_day 시작
        if ref_date.month == 1:
            start_year, start_month = ref_date.year - 1, 12
        else:
            start_year, start_month = ref_date.year, ref_date.month - 1
        start = date(start_year, start_month, salary_day)
        if salary_day == 1:
            end = ref_date.replace(day=calendar.monthrange(ref_date.year, ref_date.month)[1])
        else:
            end_day = min(salary_day - 1, calendar.monthrange(ref_date.year, ref_date.month)[1])
            end = ref_date.replace(day=end_day)
        label = f"{start_year}년 {start_month}월"

    return start, end, label


def get_cycle_for_date(db: Session, user_id: int, target: date) -> BudgetCycle:
    """target 날짜가 속하는 BudgetCycle 반환. 없으면 생성."""
    salary_day = _get_salary_day(db, user_id)
    start, end, label = _cycle_bounds(target, salary_day)

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
    """오늘 날짜 기준 현재 BudgetCycle 반환."""
    return get_cycle_for_date(db, user_id, date.today())
