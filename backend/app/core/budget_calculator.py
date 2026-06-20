from __future__ import annotations

from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle
from app.models.category import Category
from app.models.fixed_expense import FixedExpense
from app.models.income import Income, IncomeType
from app.models.transaction import Transaction
from app.schemas.budget import AvailableBudget, BillingSummary, CategoryAmount, SpendSummary


def _category_breakdown(rows: list[tuple]) -> list[CategoryAmount]:
    return [CategoryAmount(category_id=cid, category_name=name, total=total) for cid, name, total in rows]


def get_spend_summary(db: Session, user_id: int, cycle_id: int) -> SpendSummary:
    """spend_cycle 기준: 거래일이 이 사이클에 속하는 소비 합계 (카테고리별)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.spend_cycle_id == cycle_id,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return SpendSummary(cycle_id=cycle_id, total_spend=total, by_category=_category_breakdown(rows))


def get_billing_summary(db: Session, user_id: int, cycle_id: int) -> BillingSummary:
    """billing_cycle 기준: 청구일이 이 사이클에 속하는 소비 합계 (카테고리별)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.billing_cycle_id == cycle_id,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return BillingSummary(cycle_id=cycle_id, total_billing=total, by_category=_category_breakdown(rows))


def get_available_budget(db: Session, user_id: int, cycle_id: int) -> AvailableBudget:
    """
    가용 예산 = salary + extra_income - fixed_expense - billed_transactions
    """
    cycle = db.scalar(
        select(BudgetCycle).where(BudgetCycle.id == cycle_id, BudgetCycle.user_id == user_id)
    )
    if cycle is None:
        raise ValueError(f"BudgetCycle {cycle_id} not found")

    salary = cycle.salary_actual if cycle.salary_actual is not None else cycle.salary_expected

    extra_row = db.scalar(
        select(func.coalesce(func.sum(Income.actual_amount), 0))
        .where(
            Income.user_id == user_id,
            Income.budget_cycle_id == cycle_id,
            Income.type == IncomeType.extra,
        )
    )
    extra_income = Decimal(str(extra_row))

    fixed_row = db.scalar(
        select(func.coalesce(func.sum(FixedExpense.amount), 0))
        .where(FixedExpense.user_id == user_id, FixedExpense.is_active.is_(True))
    )
    fixed_expense = Decimal(str(fixed_row))

    billing_summary = get_billing_summary(db, user_id, cycle_id)
    billed_transactions = billing_summary.total_billing

    available = salary + extra_income - fixed_expense - billed_transactions

    return AvailableBudget(
        cycle_id=cycle_id,
        salary=salary,
        extra_income=extra_income,
        fixed_expense=fixed_expense,
        billed_transactions=billed_transactions,
        available=available,
        spend_summary=get_spend_summary(db, user_id, cycle_id),
        billing_summary=billing_summary,
    )
