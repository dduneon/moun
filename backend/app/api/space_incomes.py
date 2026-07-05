import calendar
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete as sql_delete, select

from app.core.deps import DbDep, SpaceDep, UserDep
from app.models.space_finance import SpaceIncome, SpaceTransaction
from app.schemas.space_common import (
    SpaceIncomeCreate,
    SpaceIncomeDelete,
    SpaceIncomePatch,
    SpaceIncomeResponse,
)

router = APIRouter(prefix="/spaces/{space_id}/incomes", tags=["space-incomes"])


def _get_or_404(db, space_id: int, income_id: int) -> SpaceIncome:
    obj = db.scalar(select(SpaceIncome).where(SpaceIncome.id == income_id, SpaceIncome.space_id == space_id))
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
        select(SpaceIncome)
        .where(SpaceIncome.space_id == space_id)
        .where((SpaceIncome.end_date.is_(None)) | (SpaceIncome.end_date > end_date_ref))
    )
    if not is_management_view:
        q = q.where(SpaceIncome.effective_from <= cutoff)

    all_rows = db.scalars(q.order_by(SpaceIncome.group_id, SpaceIncome.effective_from.asc())).all()

    groups: dict[int, list[SpaceIncome]] = {}
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


@router.get("", response_model=list[SpaceIncomeResponse])
def list_space_incomes(space: SpaceDep, db: DbDep, month: date | None = None):
    return _latest_per_group(db, space.id, for_month=month)


@router.post("", response_model=SpaceIncomeResponse, status_code=status.HTTP_201_CREATED)
def create_space_income(body: SpaceIncomeCreate, space: SpaceDep, db: DbDep, user: UserDep):
    today = date.today()
    fields = body.model_dump(exclude={"include_current_cycle"})

    if not body.include_current_cycle:
        effective_from = today + timedelta(days=1)
    else:
        effective_from = today.replace(day=1)

    obj = SpaceIncome(space_id=space.id, created_by_user_id=user.id, effective_from=effective_from, **fields)
    db.add(obj)
    db.flush()
    obj.group_id = obj.id
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{income_id}", response_model=SpaceIncomeResponse)
def get_space_income(income_id: int, space: SpaceDep, db: DbDep):
    return _get_or_404(db, space.id, income_id)


@router.patch("/{income_id}", response_model=SpaceIncomeResponse)
def patch_space_income(income_id: int, body: SpaceIncomePatch, space: SpaceDep, db: DbDep):
    current = _get_or_404(db, space.id, income_id)
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
        select(SpaceIncome).where(
            SpaceIncome.space_id == space.id,
            SpaceIncome.group_id == group_id,
            SpaceIncome.effective_from >= effective_from,
        ).order_by(SpaceIncome.effective_from.asc())
    ).all()

    base_name = current.name
    base_frequency = current.frequency
    base_scheduled_day = current.scheduled_day
    base_day_of_week = current.day_of_week
    base_expected_amount = current.expected_amount
    base_category_id = current.category_id
    base_created_by_user_id = current.created_by_user_id

    for row in later_rows:
        db.delete(row)
    db.flush()

    new_obj = SpaceIncome(
        space_id=space.id,
        created_by_user_id=base_created_by_user_id,
        name=fields.get("name", base_name),
        frequency=fields.get("frequency", base_frequency),
        scheduled_day=fields.get("scheduled_day", base_scheduled_day),
        day_of_week=fields.get("day_of_week", base_day_of_week),
        expected_amount=fields.get("expected_amount", base_expected_amount),
        category_id=fields.get("category_id", base_category_id),
        group_id=group_id,
        effective_from=effective_from,
    )
    db.add(new_obj)
    db.commit()
    db.refresh(new_obj)
    return new_obj


@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_space_income(income_id: int, body: SpaceIncomeDelete, space: SpaceDep, db: DbDep):
    obj = _get_or_404(db, space.id, income_id)
    group_id = obj.group_id or obj.id
    rows = db.scalars(
        select(SpaceIncome).where(
            SpaceIncome.space_id == space.id,
            SpaceIncome.group_id == group_id,
        )
    ).all()
    income_ids = [r.id for r in rows]

    if body.end_from is None:
        db.execute(
            sql_delete(SpaceTransaction).where(SpaceTransaction.source_income_id.in_(income_ids))
        )
        for row in rows:
            db.delete(row)
    else:
        db.execute(
            sql_delete(SpaceTransaction).where(
                SpaceTransaction.source_income_id.in_(income_ids),
                SpaceTransaction.transaction_date >= body.end_from,
            )
        )
        for row in rows:
            row.end_date = body.end_from
    db.commit()
