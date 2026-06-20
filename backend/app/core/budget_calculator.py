from __future__ import annotations

from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.budget_cycle import BudgetCycle
from app.models.category import Category
from app.models.fixed_expense import FixedExpense
from app.models.income import Income
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
    가용 예산 = expected_income - fixed_expense - billed_transactions
    expected_income: COALESCE(actual_amount, expected_amount) 합산 (예정 포함)
    confirmed_income: actual_amount 확정된 항목만 합산
    """
    # 사이클에 묶인 수입 (확정)
    confirmed_row = db.scalar(
        select(func.coalesce(func.sum(Income.actual_amount), 0))
        .where(
            Income.user_id == user_id,
            Income.budget_cycle_id == cycle_id,
            Income.actual_amount.is_not(None),
        )
    )
    # 고정 수입 (사이클 없음) 중 actual이 있는 것
    confirmed_fixed_row = db.scalar(
        select(func.coalesce(func.sum(Income.actual_amount), 0))
        .where(
            Income.user_id == user_id,
            Income.budget_cycle_id.is_(None),
            Income.actual_amount.is_not(None),
        )
    )
    confirmed_income = Decimal(str(confirmed_row)) + Decimal(str(confirmed_fixed_row))

    # 사이클에 묶인 수입 (예정 포함 COALESCE)
    cycle_expected_row = db.scalar(
        select(func.coalesce(func.sum(func.coalesce(Income.actual_amount, Income.expected_amount)), 0))
        .where(
            Income.user_id == user_id,
            Income.budget_cycle_id == cycle_id,
        )
    )
    # 고정 수입 (사이클 없음) expected_amount 합산
    fixed_expected_row = db.scalar(
        select(func.coalesce(func.sum(func.coalesce(Income.actual_amount, Income.expected_amount)), 0))
        .where(
            Income.user_id == user_id,
            Income.budget_cycle_id.is_(None),
        )
    )
    expected_income = Decimal(str(cycle_expected_row)) + Decimal(str(fixed_expected_row))

    fixed_row = db.scalar(
        select(func.coalesce(func.sum(FixedExpense.amount), 0))
        .where(FixedExpense.user_id == user_id, FixedExpense.is_active.is_(True))
    )
    fixed_expense = Decimal(str(fixed_row))

    billing_summary = get_billing_summary(db, user_id, cycle_id)
    billed_transactions = billing_summary.total_billing

    available = expected_income - fixed_expense - billed_transactions

    return AvailableBudget(
        cycle_id=cycle_id,
        confirmed_income=confirmed_income,
        expected_income=expected_income,
        fixed_expense=fixed_expense,
        billed_transactions=billed_transactions,
        available=available,
        spend_summary=get_spend_summary(db, user_id, cycle_id),
        billing_summary=billing_summary,
    )
