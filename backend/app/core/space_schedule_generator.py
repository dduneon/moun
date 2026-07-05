"""Space 고정 수입/지출 스케줄 → 실제 SpaceTransaction 자동 생성.

personal용 schedule_generator.py와 동일한 구조이나 Space 모델을 대상으로 한다.
Space 거래는 카드 결제를 지원하지 않으므로 청구일 분기 로직이 없다."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.date_occurrence import occurrence_dates as _occurrence_dates
from app.models.space_finance import (
    SpaceCategory,
    SpaceFixedExpense,
    SpaceIncome,
    SpacePaymentMethod,
    SpaceTransaction,
)

_SYSTEM_INCOME_CATEGORY = "수입"
_SYSTEM_EXPENSE_CATEGORY = "고정지출"


@dataclass
class PendingSpaceIncome:
    income: SpaceIncome
    scheduled_date: date


@dataclass
class PendingSpaceExpense:
    expense: SpaceFixedExpense
    scheduled_date: date


def _get_or_create_system_category(db: Session, space_id: int, name: str) -> int:
    cat = db.scalar(
        select(SpaceCategory).where(SpaceCategory.space_id == space_id, SpaceCategory.name == name)
    )
    if cat is None:
        cat = SpaceCategory(space_id=space_id, name=name, icon=None)
        db.add(cat)
        db.flush()
    return cat.id


def _active_incomes(db: Session, space_id: int, cycle_start: date, cycle_end: date) -> list[SpaceIncome]:
    rows = db.scalars(
        select(SpaceIncome)
        .where(SpaceIncome.space_id == space_id)
        .where(SpaceIncome.effective_from <= cycle_end)
        .where((SpaceIncome.end_date.is_(None)) | (SpaceIncome.end_date > cycle_start))
    ).all()
    seen: set[int] = set()
    result: list[SpaceIncome] = []
    for row in sorted(rows, key=lambda r: (r.group_id or r.id, -(r.effective_from.toordinal()))):
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


def _active_expenses(db: Session, space_id: int, cycle_start: date, cycle_end: date) -> list[SpaceFixedExpense]:
    rows = db.scalars(
        select(SpaceFixedExpense)
        .where(SpaceFixedExpense.space_id == space_id)
        .where(SpaceFixedExpense.is_active.is_(True))
        .where(SpaceFixedExpense.effective_from <= cycle_end)
        .where((SpaceFixedExpense.end_date.is_(None)) | (SpaceFixedExpense.end_date > cycle_start))
    ).all()
    seen: set[int] = set()
    result: list[SpaceFixedExpense] = []
    for row in sorted(rows, key=lambda r: (r.group_id or r.id, -(r.effective_from.toordinal()))):
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


def _existing_income_dates(db: Session, income_id: int, start: date, end: date) -> set[date]:
    rows = db.scalars(
        select(SpaceTransaction.transaction_date).where(
            SpaceTransaction.source_income_id == income_id,
            SpaceTransaction.transaction_date >= start,
            SpaceTransaction.transaction_date <= end,
        )
    ).all()
    return set(rows)


def _existing_expense_dates(db: Session, expense_id: int, start: date, end: date) -> set[date]:
    rows = db.scalars(
        select(SpaceTransaction.transaction_date).where(
            SpaceTransaction.source_fixed_expense_id == expense_id,
            SpaceTransaction.transaction_date >= start,
            SpaceTransaction.transaction_date <= end,
        )
    ).all()
    return set(rows)


def materialize_space_scheduled_items(
    db: Session,
    space_id: int,
    start: date,
    end: date,
) -> tuple[list[PendingSpaceIncome], list[PendingSpaceExpense]]:
    """사이클 범위 내 오늘 이전 항목을 SpaceTransaction으로 자동 생성.
    아직 날짜가 안 된 항목(예정)을 pending 목록으로 반환."""
    today = date.today()

    incomes = _active_incomes(db, space_id, start, end)
    expenses = _active_expenses(db, space_id, start, end)

    pending_incomes: list[PendingSpaceIncome] = []
    pending_expenses: list[PendingSpaceExpense] = []
    dirty = False

    for income in incomes:
        occ_start = max(start, income.effective_from)
        all_dates = _occurrence_dates(
            income.frequency,
            income.scheduled_day,
            income.day_of_week,
            income.effective_from,
            occ_start, end,
        )
        if not all_dates:
            continue

        existing = _existing_income_dates(db, income.id, start, end)
        category_id: int | None = None

        for occ in all_dates:
            if occ > today:
                pending_incomes.append(PendingSpaceIncome(income=income, scheduled_date=occ))
                continue
            if occ in existing:
                continue

            if category_id is None:
                category_id = income.category_id or _get_or_create_system_category(
                    db, space_id, _SYSTEM_INCOME_CATEGORY
                )
            db.add(SpaceTransaction(
                space_id=space_id,
                created_by_user_id=income.created_by_user_id,
                amount=income.expected_amount or Decimal(0),
                category_id=category_id,
                payment_method=SpacePaymentMethod.account,
                transaction_date=occ,
                billing_date=occ,
                name=income.name,
                source_income_id=income.id,
            ))
            dirty = True

    for expense in expenses:
        occ_start = max(start, expense.effective_from)
        all_dates = _occurrence_dates(
            expense.frequency,
            expense.billing_day,
            expense.day_of_week,
            expense.effective_from,
            occ_start, end,
        )
        if not all_dates:
            continue

        existing = _existing_expense_dates(db, expense.id, start, end)
        category_id = None

        for occ in all_dates:
            if occ > today:
                pending_expenses.append(PendingSpaceExpense(expense=expense, scheduled_date=occ))
                continue
            if occ in existing:
                continue

            if category_id is None:
                category_id = expense.category_id or _get_or_create_system_category(
                    db, space_id, _SYSTEM_EXPENSE_CATEGORY
                )

            db.add(SpaceTransaction(
                space_id=space_id,
                created_by_user_id=expense.created_by_user_id,
                amount=-abs(expense.amount),
                category_id=category_id,
                payment_method=expense.payment_method,
                transaction_date=occ,
                billing_date=occ,
                name=expense.name,
                source_fixed_expense_id=expense.id,
            ))
            dirty = True

    if dirty:
        try:
            db.commit()
        except IntegrityError:
            # 동시 요청으로 인한 중복 삽입 race condition → 롤백 후 무시
            db.rollback()

    return pending_incomes, pending_expenses
