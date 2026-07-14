from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.schedule_generator import PendingExpense, PendingIncome, materialize_scheduled_items
from app.models.category import Category
from app.models.fixed_expense import FixedExpenseType, PaymentMethod
from app.models.transaction import Transaction, TransactionType
from app.schemas.budget import AvailableBudget, BillingSummary, CategoryAmount, SavingSummary, SpendSummary


def _category_breakdown(rows: list[tuple]) -> list[CategoryAmount]:
    return [CategoryAmount(category_id=cid, category_name=name, total=tot) for cid, name, tot in rows]


def get_spend_summary(db: Session, user_id: int, start: date, end: date) -> SpendSummary:
    """transaction_date 기준 범위 내 지출 합계 (카테고리별). 저축(saving)은 제외."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.type == TransactionType.expense,
            Transaction.amount < 0,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return SpendSummary(total_spend=total, by_category=_category_breakdown(rows))


def get_saving_summary(db: Session, user_id: int, start: date, end: date) -> SavingSummary:
    """transaction_date 기준 범위 내 저축/이체 합계 (카테고리별). 소비 통계에서는 제외되지만
    가용 예산 계산에는 반영된다 (돈이 실제로 계좌에서 빠져나가기 때문)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.type == TransactionType.saving,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return SavingSummary(total_saving=total, by_category=_category_breakdown(rows))


def get_billing_summary(db: Session, user_id: int, start: date, end: date) -> BillingSummary:
    """billing_date 기준 범위 내 지출 합계 (카테고리별)."""
    rows = db.execute(
        select(Category.id, Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.category_id == Category.id)
        .where(
            Transaction.user_id == user_id,
            Transaction.billing_date >= start,
            Transaction.billing_date <= end,
            Transaction.type == TransactionType.expense,
            Transaction.amount < 0,
        )
        .group_by(Category.id, Category.name)
    ).all()

    total = sum(r[2] for r in rows) if rows else Decimal(0)
    return BillingSummary(total_billing=total, by_category=_category_breakdown(rows))


def get_available_budget(db: Session, user_id: int, start: date, end: date, label: str = "") -> AvailableBudget:
    """
    가용 예산 계산.

    - 날짜가 지난 고정 수입/지출은 Transaction으로 자동 생성 후 계산에 포함.
    - 아직 날짜가 안 된 항목은 pending으로 따로 집계.

    available = expected_income - pending_fixed_expense + spend_summary.total_spend
    """
    pending_incomes, pending_expenses = materialize_scheduled_items(db, user_id, start, end)

    # 사이클 내 실제 수입 (자동 생성된 것 + 수동으로 입력된 양수 거래 모두 포함)
    income_row = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0))
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.amount > 0,
        )
    )
    confirmed_income = Decimal(str(income_row))

    # 아직 날짜가 안 된 고정 수입 (예정)
    pending_income_total = sum(
        (p.income.expected_amount or Decimal(0) for p in pending_incomes),
        Decimal(0),
    )

    expected_income = confirmed_income + pending_income_total

    # 아직 날짜가 안 된 고정 지출/저축 (예정) — FixedExpense.type으로 분리
    pending_fixed_expense = sum(
        (p.expense.amount for p in pending_expenses if p.expense.type == FixedExpenseType.expense),
        Decimal(0),
    )
    pending_saving = sum(
        (p.expense.amount for p in pending_expenses if p.expense.type == FixedExpenseType.saving),
        Decimal(0),
    )

    spend_summary = get_spend_summary(db, user_id, start, end)

    # 이미 실행된 고정지출 트랜잭션 (source_fixed_expense_id 있는 것만, 저축 타입 제외)
    fixed_row = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0))
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.source_fixed_expense_id.is_not(None),
            Transaction.type == TransactionType.expense,
            Transaction.amount < 0,
        )
    )
    confirmed_fixed_expense = Decimal(str(fixed_row))

    saving_summary = get_saving_summary(db, user_id, start, end)
    confirmed_saving = saving_summary.total_saving

    # 가용 예산에 반영할 지출은 상품권(voucher) 사용분을 제외한다.
    # 상품권 사용은 이미 "충전" 시점에 saving으로 예산에서 차감되었으므로, 사용 시점에
    # 다시 차감하면 이중 계산이 된다. 단, spend_summary(소비 통계)에는 카테고리별로 포함된다.
    budget_spend_row = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0))
        .where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
            Transaction.type == TransactionType.expense,
            Transaction.amount < 0,
            Transaction.payment_method != PaymentMethod.voucher,
        )
    )
    budget_spend = Decimal(str(budget_spend_row))

    # 저축도 실제로 계좌에서 빠져나간 돈이므로 가용 예산에서는 차감하되,
    # "소비" 통계(spend_summary)에는 포함하지 않는다. 예정된(아직 실행 안 된) 고정
    # 저축도 같은 이유로 미리 차감한다.
    available = (
        expected_income - pending_fixed_expense - pending_saving
        + budget_spend + confirmed_saving
    )

    return AvailableBudget(
        start_date=start,
        end_date=end,
        label=label,
        confirmed_income=confirmed_income,
        expected_income=expected_income,
        fixed_expense=pending_fixed_expense,
        confirmed_fixed_expense=confirmed_fixed_expense,
        billed_transactions=spend_summary.total_spend,
        confirmed_saving=confirmed_saving,
        pending_saving=pending_saving,
        available=available,
        spend_summary=spend_summary,
        billing_summary=get_billing_summary(db, user_id, start, end),
        saving_summary=saving_summary,
    )
