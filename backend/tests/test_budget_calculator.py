from decimal import Decimal

import pytest
from sqlalchemy.orm import Session

from app.core.budget_calculator import get_available_budget, get_billing_summary, get_spend_summary
from app.core.budget_cycle import get_cycle_for_date
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income, IncomeStatus, IncomeType
from app.models.transaction import Transaction

from datetime import date


def _seed_cycle(db: Session, salary_expected=3_000_000, salary_actual=None):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    cycle.salary_expected = Decimal(salary_expected)
    cycle.salary_actual = Decimal(salary_actual) if salary_actual else None
    db.flush()
    return cycle


def _add_category(db: Session, name="식비") -> Category:
    cat = Category(name=name, icon="🍚")
    db.add(cat)
    db.flush()
    return cat


def _add_transaction(db, cat, spend_cycle, billing_cycle, amount) -> Transaction:
    t = Transaction(
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


# ── get_spend_summary ─────────────────────────────────────────────────────────

def test_spend_summary_empty(db: Session):
    cycle = _seed_cycle(db)
    summary = get_spend_summary(db, cycle.id)
    assert summary.total_spend == Decimal(0)
    assert summary.by_category == []


def test_spend_summary_groups_by_category(db: Session):
    cycle = _seed_cycle(db)
    cat1 = _add_category(db, "식비")
    cat2 = _add_category(db, "교통")

    for amt in [10000, 20000]:
        _add_transaction(db, cat1, cycle, cycle, amt)
    _add_transaction(db, cat2, cycle, cycle, 5000)

    summary = get_spend_summary(db, cycle.id)
    assert summary.total_spend == Decimal(35000)
    totals = {r.category_name: r.total for r in summary.by_category}
    assert totals["식비"] == Decimal(30000)
    assert totals["교통"] == Decimal(5000)


# ── get_billing_summary ───────────────────────────────────────────────────────

def test_billing_summary_only_counts_billing_cycle(db: Session):
    spend_cycle = _seed_cycle(db)
    billing_cycle = get_cycle_for_date(db, date(2026, 7, 21))
    billing_cycle.salary_expected = Decimal(3_000_000)
    db.flush()

    cat = _add_category(db)
    # spend는 6월 사이클, billing은 7월 사이클
    _add_transaction(db, cat, spend_cycle, billing_cycle, 50000)

    s6 = get_billing_summary(db, spend_cycle.id)
    s7 = get_billing_summary(db, billing_cycle.id)

    assert s6.total_billing == Decimal(0)
    assert s7.total_billing == Decimal(50000)


# ── get_available_budget ──────────────────────────────────────────────────────

def test_available_budget_uses_salary_actual_over_expected(db: Session):
    cycle = _seed_cycle(db, salary_expected=3_000_000, salary_actual=3_100_000)
    result = get_available_budget(db, cycle.id)
    assert result.salary == Decimal(3_100_000)


def test_available_budget_falls_back_to_expected(db: Session):
    cycle = _seed_cycle(db, salary_expected=3_000_000)
    result = get_available_budget(db, cycle.id)
    assert result.salary == Decimal(3_000_000)


def test_available_budget_full_calculation(db: Session):
    cycle = _seed_cycle(db, salary_expected=3_000_000)

    # extra income
    income = Income(
        type=IncomeType.extra,
        name="프리랜싱",
        actual_amount=Decimal(500_000),
        status=IncomeStatus.confirmed,
        budget_cycle_id=cycle.id,
    )
    db.add(income)

    # fixed expense
    fe = FixedExpense(name="넷플릭스", amount=Decimal(17_000), payment_method=PaymentMethod.card, billing_day=5)
    db.add(fe)

    # transaction (billing_cycle = 이 사이클)
    cat = _add_category(db)
    _add_transaction(db, cat, cycle, cycle, 100_000)
    db.flush()

    result = get_available_budget(db, cycle.id)
    assert result.extra_income == Decimal(500_000)
    assert result.fixed_expense == Decimal(17_000)
    assert result.billed_transactions == Decimal(100_000)
    expected = Decimal(3_000_000) + Decimal(500_000) - Decimal(17_000) - Decimal(100_000)
    assert result.available == expected


def test_available_budget_cycle_not_found(db: Session):
    with pytest.raises(ValueError, match="not found"):
        get_available_budget(db, 9999)
