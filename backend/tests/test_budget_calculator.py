from decimal import Decimal
from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_calculator import get_available_budget, get_billing_summary, get_spend_summary
from app.core.budget_cycle import get_cycle_for_date
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income
from app.models.transaction import Transaction
from app.models.user import User


def _seed_cycle(db, user):
    return get_cycle_for_date(db, user.id, date(2026, 6, 21))


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


def test_billing_summary_only_counts_billing_cycle(db: Session, user: User):
    spend_cycle = _seed_cycle(db, user)
    billing_cycle = get_cycle_for_date(db, user.id, date(2026, 7, 21))
    db.flush()
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, spend_cycle, billing_cycle, 50000)

    assert get_billing_summary(db, user.id, spend_cycle.id).total_billing == Decimal(0)
    assert get_billing_summary(db, user.id, billing_cycle.id).total_billing == Decimal(50000)


def test_available_budget_full_calculation(db: Session, user: User):
    cycle = _seed_cycle(db, user)
    db.add(Income(user_id=user.id, name="월급", actual_amount=Decimal(3_000_000), budget_cycle_id=cycle.id))
    db.add(Income(user_id=user.id, name="프리랜싱", actual_amount=Decimal(500_000), budget_cycle_id=cycle.id))
    db.add(FixedExpense(user_id=user.id, name="넷플릭스", amount=Decimal(17_000),
                        payment_method=PaymentMethod.card, billing_day=5))
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, cycle, cycle, 100_000)
    db.flush()

    r = get_available_budget(db, user.id, cycle.id)
    assert r.confirmed_income == Decimal(3_500_000)
    assert r.expected_income == Decimal(3_500_000)
    assert r.available == Decimal(3_500_000) - Decimal(17_000) - Decimal(100_000)
