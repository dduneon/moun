from __future__ import annotations

import calendar
from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.fixed_expense import FixedExpense
from app.models.income import Income
from app.models.transaction import Transaction
from app.schemas.budget import AvailableBudget, BillingSummary, CategoryAmount, SpendSummary


def _category_breakdown(rows: list[tuple]) -> list[CategoryAmount]:
    return [CategoryAmount(category_id=cid, category_name=name, total=tot) for cid, name, tot in rows]


def _scheduled_day_in_range(scheduled_day: int, start: date, end: date) -> bool:
    """scheduled_day(1~31)가 start~end 범위 안에 실제로 존재하는지 확인."""
    cur = start.replace(day=1)
    while cur <= end:
        last = calendar.monthrange(cur.year, cur.month)[1]
        actual_day = min(scheduled_day, last)
        candidate = cur.replace(day=actual_day)
        if start <= candidate <= end:
            return True
        cur = date(cur.year + (cur.month // 12), cur.month % 12 + 1, 1)
    return False


def _income_in_range(income: Income, start: date, end: date) -> bool:
    """이 수입이 해당 사이클에 포함되는지 판단."""
    if income.received_date is not None:
        return start <= income.received_date <= end
    if income.scheduled_day is not None:
        return _scheduled_day_in_range(income.scheduled_day, start, end)
    return False


def get_spend_summary(db: Session, user_id: int, start: date, end: date) -> SpendSummary:
    """transaction_date 기준 범위 내 지출 합계 (카테고리별)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.amount < 0,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return SpendSummary(total_spend=total, by_category=_category_breakdown(rows))


def get_billing_summary(db: Session, user_id: int, start: date, end: date) -> BillingSummary:
    """billing_date 기준 범위 내 지출 합계 (카테고리별)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.billing_date >= start,
            Transaction.billing_date <= end,
            Transaction.amount < 0,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return BillingSummary(total_billing=total, by_category=_category_breakdown(rows))


def get_available_budget(db: Session, user_id: int, start: date, end: date, label: str = "") -> AvailableBudget:
    """가용 예산 = expected_income - fixed_expense - spent_transactions."""
    all_incomes = db.scalars(
        select(Income).where(Income.user_id == user_id)
    ).all()

    cycle_incomes = [i for i in all_incomes if _income_in_range(i, start, end)]

    confirmed_income = sum(
        (i.actual_amount for i in cycle_incomes if i.actual_amount is not None),
        Decimal(0),
    )
    expected_income = sum(
        (i.actual_amount if i.actual_amount is not None else (i.expected_amount or Decimal(0))
         for i in cycle_incomes),
        Decimal(0),
    )

    fixed_row = db.scalar(
        select(func.coalesce(func.sum(FixedExpense.amount), 0))
        .where(FixedExpense.user_id == user_id, FixedExpense.is_active.is_(True))
    )
    fixed_expense = Decimal(str(fixed_row))

    # 거래로 직접 입력된 추가 수입 (양수 거래)
    extra_income_row = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0))
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.amount > 0,
        )
    )
    extra_income = Decimal(str(extra_income_row))

    spend_summary = get_spend_summary(db, user_id, start, end)
    total_income = expected_income + extra_income
    available = total_income - fixed_expense + spend_summary.total_spend

    return AvailableBudget(
        start_date=start,
        end_date=end,
        label=label,
        confirmed_income=confirmed_income + extra_income,
        expected_income=total_income,
        fixed_expense=fixed_expense,
        billed_transactions=spend_summary.total_spend,
        available=available,
        spend_summary=spend_summary,
        billing_summary=get_billing_summary(db, user_id, start, end),
    )
