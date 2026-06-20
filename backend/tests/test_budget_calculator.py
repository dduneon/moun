from decimal import Decimal
from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_calculator import get_available_budget, get_billing_summary, get_spend_summary
from app.core.budget_cycle import get_cycle_for_date
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income, IncomeStatus, IncomeType
from app.models.transaction import Transaction
from app.models.user import User


def _seed_cycle(db, user, salary_expected=3_000_000, salary_actual=None):
    cycle = get_cycle_for_date(db, user.id, date(2026, 6, 21))
    cycle.salary_expected = Decimal(salary_expected)
    cycle.salary_actual = Decimal(salary_actual) if salary_actual else None
    db.flush()
    return cycle


def _add_category(db, user, name="식비") -> Category:
    cat = Category(user_id=user.id, name=name, icon="🍚")
    db.add(cat)
    db.flush()
    return cat


def _add_transaction(db, user, cat, spend_cycle, billing_cycle, amount) -> Transaction:
    t = Transaction(
        user_id=user.id,
        amount=Decimal(amount),
        category_id=cat.id,
        payment_method=PaymentMethod.cash,
        transaction_date=date(2026, 6, 25),
        billing_date=date(2026, 6, 25),
        spend_cycle_id=spend_cycle.id,
        billing_cycle_id=billing_cycle.id,
    )
    db.add(t)
    db.flush()
    return t


def test_spend_summary_empty(db: Session, user: User):
    cycle = _seed_cycle(db, user)
    s = get_spend_summary(db, user.id, cycle.id)
    assert s.total_spend == Decimal(0)


def test_spend_summary_groups_by_category(db: Session, user: User):
    cycle = _seed_cycle(db, user)
    cat1 = _add_category(db, user, "식비")
    cat2 = _add_category(db, user, "교통")
    for amt in [10000, 20000]:
        _add_transaction(db, user, cat1, cycle, cycle, amt)
    _add_transaction(db, user, cat2, cycle, cycle, 5000)

    s = get_spend_summary(db, user.id, cycle.id)
    assert s.total_spend == Decimal(35000)
    totals = {r.category_name: r.total for r in s.by_category}
    assert totals["식비"] == Decimal(30000)
    assert totals["교통"] == Decimal(5000)


def test_spend_summary_isolated_between_users(db: Session, user: User, user_salary10: User):
    """두 사용자의 데이터는 서로 격리."""
    cycle1 = _seed_cycle(db, user)
    cycle2 = _seed_cycle(db, user_salary10)
    cat1 = _add_category(db, user)
    cat2 = _add_category(db, user_salary10)
    _add_transaction(db, user, cat1, cycle1, cycle1, 100_000)

    s2 = get_spend_summary(db, user_salary10.id, cycle2.id)
    assert s2.total_spend == Decimal(0)


def test_billing_summary_only_counts_billing_cycle(db: Session, user: User):
    spend_cycle = _seed_cycle(db, user)
    billing_cycle = get_cycle_for_date(db, user.id, date(2026, 7, 21))
    billing_cycle.salary_expected = Decimal(3_000_000)
    db.flush()
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, spend_cycle, billing_cycle, 50000)

    assert get_billing_summary(db, user.id, spend_cycle.id).total_billing == Decimal(0)
    assert get_billing_summary(db, user.id, billing_cycle.id).total_billing == Decimal(50000)


def test_available_budget_uses_salary_actual(db: Session, user: User):
    cycle = _seed_cycle(db, user, salary_expected=3_000_000, salary_actual=3_100_000)
    result = get_available_budget(db, user.id, cycle.id)
    assert result.salary == Decimal(3_100_000)


def test_available_budget_full_calculation(db: Session, user: User):
    cycle = _seed_cycle(db, user, salary_expected=3_000_000)
    db.add(Income(user_id=user.id, type=IncomeType.extra, name="프리랜싱",
                  actual_amount=Decimal(500_000), status=IncomeStatus.confirmed,
                  budget_cycle_id=cycle.id))
    db.add(FixedExpense(user_id=user.id, name="넷플릭스", amount=Decimal(17_000),
                        payment_method=PaymentMethod.card, billing_day=5))
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, cycle, cycle, 100_000)
    db.flush()

    r = get_available_budget(db, user.id, cycle.id)
    assert r.available == Decimal(3_000_000) + Decimal(500_000) - Decimal(17_000) - Decimal(100_000)


def test_available_budget_wrong_user_raises(db: Session, user: User, user_salary10: User):
    cycle = _seed_cycle(db, user)
    with pytest.raises(ValueError):
        get_available_budget(db, user_salary10.id, cycle.id)
