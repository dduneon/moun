from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.billing import calculate_actual_payday
from app.models.income import Income, IncomeStatus, IncomeType
from app.models.user_setting import UserSetting


def confirm_salary(db: Session, user_id: int, cycle_id: int, actual_amount: Decimal) -> Income:
    """해당 사이클의 salary income을 actual_amount로 확정 처리."""
    income = db.scalar(
        select(Income).where(
            Income.user_id == user_id,
            Income.budget_cycle_id == cycle_id,
            Income.type == IncomeType.salary,
        )
    )
    if income is None:
        raise ValueError(f"cycle {cycle_id}에 해당하는 salary income이 없습니다")

    income.actual_amount = actual_amount
    income.status = IncomeStatus.confirmed
    income.received_date = date.today()
    db.flush()
    return income


def get_pending_salary_confirmations(db: Session, user_id: int) -> list[Income]:
    """
    실제 입금 예정일(주말/공휴일 보정 포함)이 지났는데 아직 pending인 salary income 반환.
    (푸시 알림 대상 조회용)
    """
    today = date.today()
    setting = db.scalar(select(UserSetting).where(UserSetting.user_id == user_id))

    pending_incomes = db.scalars(
        select(Income).where(
            Income.user_id == user_id,
            Income.type == IncomeType.salary,
            Income.status == IncomeStatus.pending,
            Income.scheduled_day.isnot(None),
        )
    ).all()

    result = []
    for income in pending_incomes:
        # income이 속한 사이클의 연/월 기준으로 실제 입금일 계산
        if income.budget_cycle_id and setting:
            from app.models.budget_cycle import BudgetCycle  # noqa: PLC0415
            cycle = db.get(BudgetCycle, income.budget_cycle_id)
            if cycle:
                actual_day = calculate_actual_payday(cycle.start_date.year, cycle.start_date.month, setting)
                if actual_day <= today:
                    result.append(income)
        else:
            # setting 없으면 scheduled_day 그대로 비교
            if income.scheduled_day <= today.day:
                result.append(income)

    return result
