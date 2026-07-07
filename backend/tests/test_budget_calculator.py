import calendar
from decimal import Decimal
from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_calculator import (
    get_available_budget,
    get_billing_summary,
    get_saving_summary,
    get_spend_summary,
)
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, FixedExpenseType, PaymentMethod
from app.models.income import Income
from app.models.transaction import Transaction, TransactionType
from app.models.user import User

START = date(2026, 6, 1)
END = date(2026, 6, 30)


def _add_category(db, user, name="식비") -> Category:
    cat = Category(user_id=user.id, name=name, icon="🍚")
    db.add(cat)
    db.flush()
    return cat


def _add_transaction(db, user, cat, txn_date, billing_date, amount, type=TransactionType.expense) -> Transaction:
    t = Transaction(
        user_id=user.id,
        amount=Decimal(amount),
        type=type,
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
    # 과거 날짜 → 자동으로 transaction 생성됨 (오늘=2026-06-24 기준)
    db.add(Income(user_id=user.id, name="월급", scheduled_day=10,
                  expected_amount=Decimal(3_000_000)))
    db.add(Income(user_id=user.id, name="프리랜싱", scheduled_day=20,
                  expected_amount=Decimal(500_000)))
    db.add(FixedExpense(user_id=user.id, name="넷플릭스", amount=Decimal(17_000),
                        payment_method=PaymentMethod.cash, billing_day=5))
    cat = _add_category(db, user)
    _add_transaction(db, user, cat, date(2026, 6, 15), date(2026, 6, 15), -100_000)
    db.commit()

    # scheduled_day 10, 20, 5 모두 오늘(24일) 이전 → 자동 생성 포함
    r = get_available_budget(db, user.id, START, END)
    # 자동 생성된 수입 2건 + 수동 수입 없음
    assert r.confirmed_income == Decimal(3_500_000)
    assert r.expected_income == Decimal(3_500_000)
    # pending_fixed_expense = 0 (6/5 이미 지남), billed = -17000(자동) + -100000(수동)
    assert r.fixed_expense == Decimal(0)
    assert r.available == Decimal(3_500_000) - Decimal(17_000) - Decimal(100_000)


def test_saving_excluded_from_spend_but_reduces_available(db: Session, user: User):
    cat = _add_category(db, user, "저축")
    _add_transaction(db, user, cat, date(2026, 6, 10), date(2026, 6, 10), -200_000, type=TransactionType.saving)

    saving = get_saving_summary(db, user.id, START, END)
    assert saving.total_saving == Decimal(-200_000)

    # 저축은 "지출" 통계에서 제외된다
    spend = get_spend_summary(db, user.id, START, END)
    assert spend.total_spend == Decimal(0)

    # 하지만 가용 예산에서는 실제로 계좌에서 빠져나간 돈이므로 차감된다
    r = get_available_budget(db, user.id, START, END)
    assert r.confirmed_saving == Decimal(-200_000)
    assert r.available == Decimal(-200_000)


def test_fixed_saving_materializes_as_saving_transaction(db: Session, user: User):
    from app.core.schedule_generator import materialize_scheduled_items

    db.add(FixedExpense(
        user_id=user.id, name="정기적금", amount=Decimal(300_000),
        type=FixedExpenseType.saving, payment_method=PaymentMethod.account, billing_day=5,
    ))
    db.commit()

    # scheduled_day=5는 오늘(24일) 이전 → 자동 생성됨
    materialize_scheduled_items(db, user.id, START, END)

    txn = db.query(Transaction).filter(Transaction.source_fixed_expense_id.isnot(None)).one()
    assert txn.type == TransactionType.saving
    assert txn.amount == Decimal(-300_000)

    saving = get_saving_summary(db, user.id, START, END)
    assert saving.total_saving == Decimal(-300_000)
    spend = get_spend_summary(db, user.id, START, END)
    assert spend.total_spend == Decimal(0)

    # 고정 저축은 "고정 지출" 집계와 분리되어야 한다 (섞이면 안 됨)
    r = get_available_budget(db, user.id, START, END)
    assert r.confirmed_fixed_expense == Decimal(0)
    assert r.confirmed_saving == Decimal(-300_000)


def test_pending_fixed_saving_deducted_from_available_separately(db: Session, user: User):
    # 항상 미래인 사이클(다음 달 전체)을 사용해 "오늘 이전 발생분 자동 생성"과
    # 무관하게 전부 pending으로 집계되도록 한다.
    today = date.today()
    next_month_start = date(today.year + (1 if today.month == 12 else 0), (today.month % 12) + 1, 1)
    next_month_end = date(next_month_start.year, next_month_start.month, calendar.monthrange(next_month_start.year, next_month_start.month)[1])

    db.add(FixedExpense(
        user_id=user.id, name="예정 적금", amount=Decimal(100_000),
        type=FixedExpenseType.saving, payment_method=PaymentMethod.account, billing_day=15,
    ))
    db.add(FixedExpense(
        user_id=user.id, name="예정 월세", amount=Decimal(50_000),
        type=FixedExpenseType.expense, payment_method=PaymentMethod.account, billing_day=15,
    ))
    db.commit()

    r = get_available_budget(db, user.id, next_month_start, next_month_end)
    assert r.pending_saving == Decimal(100_000)
    assert r.fixed_expense == Decimal(50_000)
    assert r.available == -Decimal(150_000)
