from decimal import Decimal
from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_calculator import get_available_budget, get_billing_summary, get_spend_summary
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income
from app.models.transaction import Transaction
from app.models.user import User

START = date(2026, 6, 1)
END = date(2026, 6, 30)


def _add_category(db, user, name="식비") -> Category:
    cat = Category(user_id=user.id, name=name, icon="🍚")
    db.add(cat)
    db.flush()
    return cat


def _add_transaction(db, user, cat, txn_date, billing_date, amount) -> Transaction:
    t = Transaction(
        user_id=user.id,
        amount=Decimal(amount),
        category_id=cat.id,
        payment_method=PaymentMethod.cash,
        transaction_date=txn_date,
        billing_date=billing_date,
    )
    db.add(t)
    db.flush()
    return t


def test_spend_summary_empty(db: Session, user: User):
    s = get_spend_summary(db, user.id, START, END)
    assert s.total_spend == Decimal(0)


def test_spend_summary_groups_by_category(db: Session, user: User):
    cat1 = _add_category(db, user, "식비")
    cat2 = _add_category(db, user, "교통")
    for amt in [-10000, -20000]:
        _add_transaction(db, user, cat1, date(2026, 6, 15), date(2026, 6, 15), amt)
    _add_transaction(db, user, cat2, date(2026, 6, 20), date(2026, 6, 20), -5000)

    s = get_spend_summary(db, user.id, START, END)
    assert s.total_spend == Decimal(-35000)
    totals = {r.category_name: r.total for r in s.by_category}
    assert totals["식비"] == Decimal(-30000)
    assert totals["교통"] == Decimal(-5000)


def test_billing_summary_uses_billing_date(db: Session, user: User):
    cat = _add_category(db, user)
    # 거래일은 6월, 청구일은 7월
    _add_transaction(db, user, cat, date(2026, 6, 15), date(2026, 7, 5), -50000)

    assert get_billing_summary(db, user.id, START, END).total_billing == Decimal(0)
    assert get_billing_summary(db, user.id, date(2026, 7, 1), date(2026, 7, 31)).total_billing == Decimal(-50000)


def test_available_budget_full_calculation(db: Session, user: User):
    db.add(Income(user_id=user.id, name="월급", actual_amount=Decimal(3_000_000),
                  received_date=date(2026, 6, 10)))
    db.add(Income(user_id=user.id, name="프리랜싱", actual_amount=Decimal(500_000),
                  received_date=date(2026, 6, 20)))
    db.add(FixedExpense(user_id=user.id, name="넷플릭스", amount=Decimal(17_000),
                        payment_method=PaymentMethod.card, billing_day=5))
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, date(2026, 6, 15), date(2026, 6, 15), -100_000)
    db.flush()

    r = get_available_budget(db, user.id, START, END)
    assert r.confirmed_income == Decimal(3_500_000)
    assert r.expected_income == Decimal(3_500_000)
    assert r.available == Decimal(3_500_000) - Decimal(17_000) - Decimal(100_000)
