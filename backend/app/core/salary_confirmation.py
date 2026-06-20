from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.income import Income, IncomeStatus, IncomeType


def confirm_salary(db: Session, cycle_id: int, actual_amount: Decimal) -> Income:
    """해당 사이클의 salary income을 actual_amount로 확정 처리."""
    income = db.scalar(
        select(Income).where(
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


def get_pending_salary_confirmations(db: Session) -> list[Income]:
    """
    scheduled_day가 지났는데 아직 pending 상태인 salary income 목록 반환.
    (푸시 알림 대상 조회용)
    """
    today = date.today()
    rows = db.scalars(
        select(Income).where(
            Income.type == IncomeType.salary,
            Income.status == IncomeStatus.pending,
            Income.scheduled_day.isnot(None),
            Income.scheduled_day <= today.day,
        )
    ).all()
    return list(rows)
