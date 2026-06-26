from datetime import date

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete as sql_delete, select

from app.core.deps import DbDep, UserDep
from app.models.fixed_expense import FixedExpense
from app.models.transaction import Transaction
from app.schemas.common import FixedExpenseCreate, FixedExpenseDelete, FixedExpensePatch, FixedExpenseResponse

router = APIRouter(prefix="/fixed-expenses", tags=["fixed-expenses"])


def _get_or_404(db, user_id: int, obj_id: int) -> FixedExpense:
    obj = db.scalar(select(FixedExpense).where(FixedExpense.id == obj_id, FixedExpense.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


def _latest_per_group(db, user_id: int, for_month: date | None = None):
    """그룹별로 for_month 이전의 가장 최신 버전 반환. for_month=None이면 현재 활성 버전."""
    today_month = date.today().replace(day=1)
    ref_month = for_month if for_month is not None else today_month

    q = (
        select(FixedExpense)
        .where(FixedExpense.user_id == user_id)
        .where(FixedExpense.is_active.is_(True))
        .where(FixedExpense.effective_from <= ref_month)
        .where((FixedExpense.end_date.is_(None)) | (FixedExpense.end_date > ref_month))
    )

    all_rows = db.scalars(q.order_by(FixedExpense.group_id, FixedExpense.effective_from.desc())).all()

    seen: set[int] = set()
    result = []
    for row in all_rows:
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


@router.get("", response_model=list[FixedExpenseResponse])
def list_fixed_expenses(db: DbDep, user: UserDep, month: date | None = None):
    return _latest_per_group(db, user.id, for_month=month)


@router.post("", response_model=FixedExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_fixed_expense(body: FixedExpenseCreate, db: DbDep, user: UserDep):
    today = date.today()
    fields = body.model_dump(exclude={"include_current_cycle"})

    # 이번 달 billing_day가 이미 지났는데 이번 달 포함 안 할 경우 → 다음 달부터 추적
    if not body.include_current_cycle:
        next_month = (date(today.year, today.month + 1, 1)
                      if today.month < 12
                      else date(today.year + 1, 1, 1))
        effective_from = next_month
    else:
        effective_from = today.replace(day=1)

    obj = FixedExpense(user_id=user.id, effective_from=effective_from, **fields)
    db.add(obj)
    db.flush()
    obj.group_id = obj.id
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{obj_id}", response_model=FixedExpenseResponse)
def get_fixed_expense(obj_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, obj_id)


@router.patch("/{obj_id}", response_model=FixedExpenseResponse)
def patch_fixed_expense(obj_id: int, body: FixedExpensePatch, db: DbDep, user: UserDep):
    current = _get_or_404(db, user.id, obj_id)
    fields = body.model_dump(exclude_unset=True)
    effective_from = fields.pop("effective_from", None)

    if not fields:
        return current

    group_id = current.group_id or current.id

    if effective_from is None:
        # effective_from 미지정 → 단순 인플레이스 수정
        for k, v in fields.items():
            setattr(current, k, v)
        db.commit()
        db.refresh(current)
        return current

    # effective_from 이후 버전들을 모두 제거하고 새 버전 삽입
    later_rows = db.scalars(
        select(FixedExpense).where(
            FixedExpense.user_id == user.id,
            FixedExpense.group_id == group_id,
            FixedExpense.effective_from >= effective_from,
        ).order_by(FixedExpense.effective_from.asc())
    ).all()

    base_name = current.name
    base_amount = current.amount
    base_payment_method = current.payment_method
    base_frequency = current.frequency
    base_billing_day = current.billing_day
    base_day_of_week = current.day_of_week

    for row in later_rows:
        db.delete(row)
    db.flush()

    new_obj = FixedExpense(
        user_id=user.id,
        name=fields.get("name", base_name),
        amount=fields.get("amount", base_amount),
        payment_method=fields.get("payment_method", base_payment_method),
        frequency=fields.get("frequency", base_frequency),
        billing_day=fields.get("billing_day", base_billing_day),
        day_of_week=fields.get("day_of_week", base_day_of_week),
        group_id=group_id,
        effective_from=effective_from,
        is_active=True,
    )
    db.add(new_obj)
    db.commit()
    db.refresh(new_obj)
    return new_obj


@router.delete("/{obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_fixed_expense(obj_id: int, body: FixedExpenseDelete, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, obj_id)
    group_id = obj.group_id or obj.id
    rows = db.scalars(
        select(FixedExpense).where(
            FixedExpense.user_id == user.id,
            FixedExpense.group_id == group_id,
        )
    ).all()
    expense_ids = [r.id for r in rows]

    if body.end_from is None:
        # 전체 삭제: 자동 생성된 트랜잭션도 함께 삭제
        db.execute(
            sql_delete(Transaction).where(
                Transaction.source_fixed_expense_id.in_(expense_ids)
            )
        )
        for row in rows:
            db.delete(row)
    else:
        # 소프트 삭제: end_from 이후 자동 생성 트랜잭션 삭제
        db.execute(
            sql_delete(Transaction).where(
                Transaction.source_fixed_expense_id.in_(expense_ids),
                Transaction.transaction_date >= body.end_from,
            )
        )
        for row in rows:
            row.end_date = body.end_from
    db.commit()
