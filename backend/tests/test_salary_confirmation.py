from datetime import date
from decimal import Decimal
from unittest.mock import patch

import pytest
from sqlalchemy.orm import Session

from app.core.budget_cycle import get_cycle_for_date
from app.core.salary_confirmation import confirm_salary, get_pending_salary_confirmations
from app.models.income import Income, IncomeStatus, IncomeType


def _add_salary_income(db: Session, cycle_id: int, scheduled_day: int = 21) -> Income:
    income = Income(
        type=IncomeType.salary,
        name="본급여",
        expected_amount=Decimal(3_000_000),
        scheduled_day=scheduled_day,
        status=IncomeStatus.pending,
        budget_cycle_id=cycle_id,
    )
    db.add(income)
    db.flush()
    return income


def test_confirm_salary_updates_income(db: Session):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(3_000_000)
    db.flush()
    _add_salary_income(db, cycle.id)

    with patch("app.core.salary_confirmation.date") as mock_date:
        mock_date.today.return_value = date(2026, 6, 21)
        income = confirm_salary(db, cycle.id, Decimal(3_050_000))

    assert income.actual_amount == Decimal(3_050_000)
    assert income.status == IncomeStatus.confirmed
    assert income.received_date == date(2026, 6, 21)


def test_confirm_salary_raises_when_no_salary_income(db: Session):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(3_000_000)
    db.flush()

    with pytest.raises(ValueError, match="salary income이 없습니다"):
        confirm_salary(db, cycle.id, Decimal(3_000_000))


def test_get_pending_salary_confirmations_returns_overdue(db: Session):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(3_000_000)
    db.flush()
    _add_salary_income(db, cycle.id, scheduled_day=21)

    # 오늘이 22일이면 21일이 지난 것 → pending 대상
    with patch("app.core.salary_confirmation.date") as mock_date:
        mock_date.today.return_value = date(2026, 6, 22)
        # get_pending_salary_confirmations는 date.today()를 사용
        from app.core import salary_confirmation
        import importlib
        # today.day == 22 → scheduled_day 21 <= 22 → 대상에 포함
        results = get_pending_salary_confirmations(db)

    assert len(results) == 1
    assert results[0].scheduled_day == 21


def test_get_pending_salary_confirmations_excludes_confirmed(db: Session):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(3_000_000)
    db.flush()
    income = _add_salary_income(db, cycle.id, scheduled_day=21)
    income.status = IncomeStatus.confirmed
    db.flush()

    results = get_pending_salary_confirmations(db)
    assert len(results) == 0


def test_get_pending_salary_confirmations_excludes_future_day(db: Session):
    """scheduled_day가 아직 안 됐으면 알림 대상 아님."""
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(3_000_000)
    db.flush()
    _add_salary_income(db, cycle.id, scheduled_day=25)

    with patch("app.core.salary_confirmation.date") as mock_date:
        mock_date.today.return_value = date(2026, 6, 22)
        results = get_pending_salary_confirmations(db)

    assert len(results) == 0
