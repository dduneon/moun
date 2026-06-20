from datetime import date
from decimal import Decimal
from unittest.mock import patch

import pytest
from sqlalchemy.orm import Session

from app.core.budget_cycle import get_cycle_for_date
from app.core.salary_confirmation import confirm_salary, get_pending_salary_confirmations
from app.models.income import Income, IncomeStatus, IncomeType
from app.models.user import User


def _add_salary(db, user, cycle, scheduled_day=21):
    income = Income(
        user_id=user.id,
        type=IncomeType.salary,
        name="본급여",
        expected_amount=Decimal(3_000_000),
        scheduled_day=scheduled_day,
        status=IncomeStatus.pending,
        budget_cycle_id=cycle.id,
    )
    db.add(income)
    db.flush()
    return income


def _cycle(db, user, ref=date(2026, 6, 21)):
    c = get_cycle_for_date(db, user.id, ref)
    c.salary_expected = Decimal(3_000_000)
    db.flush()
    return c


def test_confirm_salary(db: Session, user: User):
    cycle = _cycle(db, user)
    _add_salary(db, user, cycle)

    with patch("app.core.salary_confirmation.date") as m:
        m.today.return_value = date(2026, 6, 21)
        income = confirm_salary(db, user.id, cycle.id, Decimal(3_050_000))

    assert income.actual_amount == Decimal(3_050_000)
    assert income.status == IncomeStatus.confirmed
    assert income.received_date == date(2026, 6, 21)


def test_confirm_salary_no_income_raises(db: Session, user: User):
    cycle = _cycle(db, user)
    with pytest.raises(ValueError, match="salary income이 없습니다"):
        confirm_salary(db, user.id, cycle.id, Decimal(3_000_000))


def test_pending_confirmations_overdue(db: Session, user: User):
    """실제 입금 예정일(주말 보정 후)이 지난 pending → 반환."""
    cycle = _cycle(db, user)
    _add_salary(db, user, cycle, scheduled_day=21)

    # 2026-06-21은 일요일 → prev_business → 2026-06-19(금)
    # 오늘이 6/19 이상이면 대상
    with patch("app.core.salary_confirmation.date") as m:
        m.today.return_value = date(2026, 6, 19)
        results = get_pending_salary_confirmations(db, user.id)
    assert len(results) == 1


def test_pending_confirmations_not_yet(db: Session, user: User):
    """아직 실제 입금일 전 → 빈 리스트."""
    cycle = _cycle(db, user)
    _add_salary(db, user, cycle, scheduled_day=21)

    # 2026-06-18(목): 실제 입금일(6/19)보다 하루 전
    with patch("app.core.salary_confirmation.date") as m:
        m.today.return_value = date(2026, 6, 18)
        results = get_pending_salary_confirmations(db, user.id)
    assert len(results) == 0


def test_pending_confirmations_excludes_confirmed(db: Session, user: User):
    cycle = _cycle(db, user)
    income = _add_salary(db, user, cycle)
    income.status = IncomeStatus.confirmed
    db.flush()
    results = get_pending_salary_confirmations(db, user.id)
    assert len(results) == 0


def test_pending_confirmations_isolated_by_user(db: Session, user: User, user_salary10: User):
    """다른 사용자의 pending은 조회되지 않음."""
    cycle1 = _cycle(db, user)
    _add_salary(db, user, cycle1)

    with patch("app.core.salary_confirmation.date") as m:
        m.today.return_value = date(2026, 6, 22)
        results = get_pending_salary_confirmations(db, user_salary10.id)
    assert len(results) == 0
