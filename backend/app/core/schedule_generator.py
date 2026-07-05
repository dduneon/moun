"""고정 수입/지출 스케줄 → 실제 Transaction 자동 생성."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.date_occurrence import occurrence_dates as _occurrence_dates
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income
from app.models.transaction import Transaction

_SYSTEM_INCOME_CATEGORY = "수입"
_SYSTEM_EXPENSE_CATEGORY = "고정지출"


@dataclass
class PendingIncome:
    income: Income
    scheduled_date: date


@dataclass
class PendingExpense:
    expense: FixedExpense
    scheduled_date: date


# ── 시스템 카테고리 ────────────────────────────────────────────────────────────

def _get_or_create_system_category(db: Session, user_id: int, name: str) -> int:
    cat = db.scalar(
        select(Category).where(Category.user_id == user_id, Category.name == name)
    )
    if cat is None:
        cat = Category(user_id=user_id, name=name, icon=None)
        db.add(cat)
        db.flush()
    return cat.id


# ── 활성 템플릿 조회 ──────────────────────────────────────────────────────────

def _active_incomes(db: Session, user_id: int, cycle_start: date, cycle_end: date) -> list[Income]:
    """이 사이클(cycle_start~cycle_end) 안에 하루라도 걸치는 그룹별 최신 버전 반환.
    실제 발생일 필터링은 _occurrence_dates 호출 시 effective_from으로 별도 처리한다."""
    rows = db.scalars(
        select(Income)
        .where(Income.user_id == user_id)
        .where(Income.effective_from <= cycle_end)
        .where((Income.end_date.is_(None)) | (Income.end_date > cycle_start))
    ).all()
    seen: set[int] = set()
    result: list[Income] = []
    for row in sorted(rows, key=lambda r: (r.group_id or r.id, -(r.effective_from.toordinal()))):
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


def _active_expenses(db: Session, user_id: int, cycle_start: date, cycle_end: date) -> list[FixedExpense]:
    """이 사이클(cycle_start~cycle_end) 안에 하루라도 걸치는 그룹별 최신 버전 반환.
    실제 발생일 필터링은 _occurrence_dates 호출 시 effective_from으로 별도 처리한다."""
    rows = db.scalars(
        select(FixedExpense)
        .where(FixedExpense.user_id == user_id)
        .where(FixedExpense.is_active.is_(True))
        .where(FixedExpense.effective_from <= cycle_end)
        .where((FixedExpense.end_date.is_(None)) | (FixedExpense.end_date > cycle_start))
    ).all()
    seen: set[int] = set()
    result: list[FixedExpense] = []
    for row in sorted(rows, key=lambda r: (r.group_id or r.id, -(r.effective_from.toordinal()))):
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


# ── 이미 생성된 transaction 날짜 세트 ────────────────────────────────────────

def _existing_income_dates(db: Session, income_id: int, start: date, end: date) -> set[date]:
    rows = db.scalars(
        select(Transaction.transaction_date).where(
            Transaction.source_income_id == income_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
        )
    ).all()
    return set(rows)


def _existing_expense_dates(db: Session, expense_id: int, start: date, end: date) -> set[date]:
    rows = db.scalars(
        select(Transaction.transaction_date).where(
            Transaction.source_fixed_expense_id == expense_id,
            Transaction.transaction_date >= start,
            Transaction.transaction_date <= end,
        )
    ).all()
    return set(rows)



# ── 메인 함수 ─────────────────────────────────────────────────────────────────

def materialize_scheduled_items(
    db: Session,
    user_id: int,
    start: date,
    end: date,
) -> tuple[list[PendingIncome], list[PendingExpense]]:
    """
    사이클 범위 내 오늘 이전 항목을 Transaction으로 자동 생성.
    아직 날짜가 안 된 항목(예정)을 pending 목록으로 반환.
    """
    today = date.today()

    incomes = _active_incomes(db, user_id, start, end)
    expenses = _active_expenses(db, user_id, start, end)

    pending_incomes: list[PendingIncome] = []
    pending_expenses: list[PendingExpense] = []
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
                pending_incomes.append(PendingIncome(income=income, scheduled_date=occ))
                continue
            if occ in existing:
                continue

            if category_id is None:
                category_id = income.category_id or _get_or_create_system_category(
                    db, user_id, _SYSTEM_INCOME_CATEGORY
                )
            db.add(Transaction(
                user_id=user_id,
                amount=income.expected_amount or Decimal(0),
                category_id=category_id,
                payment_method=PaymentMethod.account,
                card_id=None,
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
                pending_expenses.append(PendingExpense(expense=expense, scheduled_date=occ))
                continue
            if occ in existing:
                continue

            if category_id is None:
                category_id = expense.category_id or _get_or_create_system_category(
                    db, user_id, _SYSTEM_EXPENSE_CATEGORY
                )

            billing_date = occ
            if expense.payment_method == PaymentMethod.card and expense.card_id is not None:
                from app.core.billing import calculate_billing_date
                from app.models.card import Card
                card = db.scalar(select(Card).where(Card.id == expense.card_id))
                if card:
                    billing_date = calculate_billing_date(occ, PaymentMethod.card, card)

            db.add(Transaction(
                user_id=user_id,
                amount=-abs(expense.amount),
                category_id=category_id,
                payment_method=expense.payment_method,
                card_id=expense.card_id,
                transaction_date=occ,
                billing_date=billing_date,
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
