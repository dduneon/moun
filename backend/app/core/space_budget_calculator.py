"""Space 예산 계산. personal용 budget_calculator.py와 동일한 구조를 Space 모델 대상으로 적용."""
from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.space_schedule_generator import materialize_space_scheduled_items
from app.models.space_finance import SpaceCategory, SpaceTransaction
from app.schemas.budget import AvailableBudget, BillingSummary, CategoryAmount, SpendSummary


def _category_breakdown(rows: list[tuple]) -> list[CategoryAmount]:
    return [CategoryAmount(category_id=cid, category_name=name, total=tot) for cid, name, tot in rows]


def get_space_spend_summary(db: Session, space_id: int, start: date, end: date) -> SpendSummary:
    rows = db.execute(
        select(SpaceCategory.id, SpaceCategory.name, func.sum(SpaceTransaction.amount))
        .join(SpaceCategory, SpaceTransaction.category_id == SpaceCategory.id)
        .where(
            SpaceTransaction.space_id == space_id,
            SpaceTransaction.transaction_date >= start,
            SpaceTransaction.transaction_date <= end,
            SpaceTransaction.amount < 0,
        )
        .group_by(SpaceCategory.id, SpaceCategory.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return SpendSummary(total_spend=total, by_category=_category_breakdown(rows))


def get_space_billing_summary(db: Session, space_id: int, start: date, end: date) -> BillingSummary:
    rows = db.execute(
        select(SpaceCategory.id, SpaceCategory.name, func.sum(SpaceTransaction.amount))
        .join(SpaceCategory, SpaceTransaction.category_id == SpaceCategory.id)
        .where(
            SpaceTransaction.space_id == space_id,
            SpaceTransaction.billing_date >= start,
            SpaceTransaction.billing_date <= end,
            SpaceTransaction.amount < 0,
        )
        .group_by(SpaceCategory.id, SpaceCategory.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return BillingSummary(total_billing=total, by_category=_category_breakdown(rows))


def get_space_available_budget(db: Session, space_id: int, start: date, end: date, label: str = "") -> AvailableBudget:
    pending_incomes, pending_expenses = materialize_space_scheduled_items(db, space_id, start, end)

    income_row = db.scalar(
        select(func.coalesce(func.sum(SpaceTransaction.amount), 0))
        .where(
            SpaceTransaction.space_id == space_id,
            SpaceTransaction.transaction_date >= start,
            SpaceTransaction.transaction_date <= end,
            SpaceTransaction.amount > 0,
        )
    )
    confirmed_income = Decimal(str(income_row))

    pending_income_total = sum(
        (p.income.expected_amount or Decimal(0) for p in pending_incomes),
        Decimal(0),
    )

    expected_income = confirmed_income + pending_income_total

    pending_fixed_expense = sum(
        (p.expense.amount for p in pending_expenses),
        Decimal(0),
    )

    spend_summary = get_space_spend_summary(db, space_id, start, end)

    fixed_row = db.scalar(
        select(func.coalesce(func.sum(SpaceTransaction.amount), 0))
        .where(
            SpaceTransaction.space_id == space_id,
            SpaceTransaction.transaction_date >= start,
            SpaceTransaction.transaction_date <= end,
            SpaceTransaction.source_fixed_expense_id.is_not(None),
            SpaceTransaction.amount < 0,
        )
    )
    confirmed_fixed_expense = Decimal(str(fixed_row))

    available = expected_income - pending_fixed_expense + spend_summary.total_spend

    return AvailableBudget(
        start_date=start,
        end_date=end,
        label=label,
        confirmed_income=confirmed_income,
        expected_income=expected_income,
        fixed_expense=pending_fixed_expense,
        confirmed_fixed_expense=confirmed_fixed_expense,
        billed_transactions=spend_summary.total_spend,
        available=available,
        spend_summary=spend_summary,
        billing_summary=get_space_billing_summary(db, space_id, start, end),
    )
