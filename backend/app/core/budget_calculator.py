from __future__ import annotations

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
    # received_date가 범위 안에 있는 수입 (확정)
    confirmed_row = db.scalar(
        select(func.coalesce(func.sum(Income.actual_amount), 0))
        .where(
            Income.user_id == user_id,
            Income.actual_amount.is_not(None),
            Income.received_date >= start,
            Income.received_date <= end,
        )
    )
    confirmed_income = Decimal(str(confirmed_row))

    # scheduled_day가 범위 내에 해당하거나 received_date가 범위 내인 수입 (예정 포함)
    # scheduled_day 기반 수입: 범위 내에 해당 월의 scheduled_day가 포함되면 포함
    # 단순하게: received_date가 범위 내이거나, received_date 없고 scheduled_day 기반으로 이번 사이클에 해당하는 것
    expected_row = db.scalar(
        select(func.coalesce(func.sum(func.coalesce(Income.actual_amount, Income.expected_amount)), 0))
        .where(
            Income.user_id == user_id,
            Income.received_date >= start,
            Income.received_date <= end,
        )
    )
    # scheduled_day 기반 (received_date 없는 것)
    scheduled_row = db.scalar(
        select(func.coalesce(func.sum(func.coalesce(Income.actual_amount, Income.expected_amount)), 0))
        .where(
            Income.user_id == user_id,
            Income.received_date.is_(None),
        )
    )
    expected_income = Decimal(str(expected_row)) + Decimal(str(scheduled_row))

    fixed_row = db.scalar(
        select(func.coalesce(func.sum(FixedExpense.amount), 0))
        .where(FixedExpense.user_id == user_id, FixedExpense.is_active.is_(True))
    )
    fixed_expense = Decimal(str(fixed_row))

    spend_summary = get_spend_summary(db, user_id, start, end)
    available = expected_income - fixed_expense + spend_summary.total_spend

    return AvailableBudget(
        start_date=start,
        end_date=end,
        label=label,
        confirmed_income=confirmed_income,
        expected_income=expected_income,
        fixed_expense=fixed_expense,
        billed_transactions=spend_summary.total_spend,
        available=available,
        spend_summary=spend_summary,
        billing_summary=get_billing_summary(db, user_id, start, end),
    )
