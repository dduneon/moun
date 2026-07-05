import calendar
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete as sql_delete, select

from app.core.deps import DbDep, SpaceDep, UserDep
from app.models.space_finance import SpaceFixedExpense, SpaceTransaction
from app.schemas.space_common import (
    SpaceFixedExpenseCreate,
    SpaceFixedExpenseDelete,
    SpaceFixedExpensePatch,
    SpaceFixedExpenseResponse,
)

router = APIRouter(prefix="/spaces/{space_id}/fixed-expenses", tags=["space-fixed-expenses"])


def _get_or_404(db, space_id: int, obj_id: int) -> SpaceFixedExpense:
    obj = db.scalar(
        select(SpaceFixedExpense).where(SpaceFixedExpense.id == obj_id, SpaceFixedExpense.space_id == space_id)
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


def _month_end(month_start: date) -> date:
    last = calendar.monthrange(month_start.year, month_start.month)[1]
    return month_start.replace(day=last)


def _latest_per_group(db, space_id: int, for_month: date | None = None):
    is_management_view = for_month is None
    cutoff = date.today() if is_management_view else _month_end(for_month)
    end_date_ref = date.today() if is_management_view else for_month

    q = (
        select(SpaceFixedExpense)
        .where(SpaceFixedExpense.space_id == space_id)
        .where(SpaceFixedExpense.is_active.is_(True))
        .where((SpaceFixedExpense.end_date.is_(None)) | (SpaceFixedExpense.end_date > end_date_ref))
    )
    if not is_management_view:
        q = q.where(SpaceFixedExpense.effective_from <= cutoff)

    all_rows = db.scalars(q.order_by(SpaceFixedExpense.group_id, SpaceFixedExpense.effective_from.asc())).all()

    groups: dict[int, list[SpaceFixedExpense]] = {}
    for row in all_rows:
        gid = row.group_id or row.id
        groups.setdefault(gid, []).append(row)

    result = []
    for rows in groups.values():
        current = [r for r in rows if r.effective_from <= cutoff]
        if current:
            result.append(current[-1])
        elif is_management_view:
            result.append(rows[0])
    return result


@router.get("", response_model=list[SpaceFixedExpenseResponse])
def list_space_fixed_expenses(space: SpaceDep, db: DbDep, month: date | None = None):
    return _latest_per_group(db, space.id, for_month=month)


@router.post("", response_model=SpaceFixedExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_space_fixed_expense(body: SpaceFixedExpenseCreate, space: SpaceDep, db: DbDep, user: UserDep):
    today = date.today()
    fields = body.model_dump(exclude={"include_current_cycle"})

    if not body.include_current_cycle:
        effective_from = today + timedelta(days=1)
    else:
        effective_from = today.replace(day=1)

    obj = SpaceFixedExpense(
        space_id=space.id, created_by_user_id=user.id, effective_from=effective_from, **fields
    )
    db.add(obj)
    db.flush()
    obj.group_id = obj.id
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{obj_id}", response_model=SpaceFixedExpenseResponse)
def get_space_fixed_expense(obj_id: int, space: SpaceDep, db: DbDep):
    return _get_or_404(db, space.id, obj_id)


@router.patch("/{obj_id}", response_model=SpaceFixedExpenseResponse)
def patch_space_fixed_expense(obj_id: int, body: SpaceFixedExpensePatch, space: SpaceDep, db: DbDep):
    current = _get_or_404(db, space.id, obj_id)
    fields = body.model_dump(exclude_unset=True)
    effective_from = fields.pop("effective_from", None)

    if not fields:
        return current

    group_id = current.group_id or current.id

    if effective_from is None:
        for k, v in fields.items():
            setattr(current, k, v)
        db.commit()
        db.refresh(current)
        return current

    later_rows = db.scalars(
        select(SpaceFixedExpense).where(
            SpaceFixedExpense.space_id == space.id,
            SpaceFixedExpense.group_id == group_id,
            SpaceFixedExpense.effective_from >= effective_from,
        ).order_by(SpaceFixedExpense.effective_from.asc())
    ).all()

    base_name = current.name
    base_amount = current.amount
    base_payment_method = current.payment_method
    base_frequency = current.frequency
    base_billing_day = current.billing_day
    base_day_of_week = current.day_of_week
    base_category_id = current.category_id
    base_created_by_user_id = current.created_by_user_id

    for row in later_rows:
        db.delete(row)
    db.flush()

    new_obj = SpaceFixedExpense(
        space_id=space.id,
        created_by_user_id=base_created_by_user_id,
        name=fields.get("name", base_name),
        amount=fields.get("amount", base_amount),
        payment_method=fields.get("payment_method", base_payment_method),
        frequency=fields.get("frequency", base_frequency),
        billing_day=fields.get("billing_day", base_billing_day),
        day_of_week=fields.get("day_of_week", base_day_of_week),
        category_id=fields.get("category_id", base_category_id),
        group_id=group_id,
        effective_from=effective_from,
        is_active=True,
    )
    db.add(new_obj)
    db.commit()
    db.refresh(new_obj)
    return new_obj


@router.delete("/{obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_space_fixed_expense(obj_id: int, body: SpaceFixedExpenseDelete, space: SpaceDep, db: DbDep):
    obj = _get_or_404(db, space.id, obj_id)
    group_id = obj.group_id or obj.id
    rows = db.scalars(
        select(SpaceFixedExpense).where(
            SpaceFixedExpense.space_id == space.id,
            SpaceFixedExpense.group_id == group_id,
        )
    ).all()
    expense_ids = [r.id for r in rows]

    if body.end_from is None:
        db.execute(
            sql_delete(SpaceTransaction).where(SpaceTransaction.source_fixed_expense_id.in_(expense_ids))
        )
        for row in rows:
            db.delete(row)
    else:
        db.execute(
            sql_delete(SpaceTransaction).where(
                SpaceTransaction.source_fixed_expense_id.in_(expense_ids),
                SpaceTransaction.transaction_date >= body.end_from,
            )
        )
        for row in rows:
            row.end_date = body.end_from
    db.commit()
