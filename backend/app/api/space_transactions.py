from datetime import date

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.budget_cycle import get_current_cycle
from app.core.deps import DbDep, SpaceDep, UserDep
from app.core.space_schedule_generator import materialize_space_scheduled_items
from app.models.space_finance import SpaceTransaction
from app.schemas.space_common import SpaceTransactionCreate, SpaceTransactionPatch, SpaceTransactionResponse

router = APIRouter(prefix="/spaces/{space_id}/transactions", tags=["space-transactions"])


def _get_or_404(db: DbDep, space_id: int, txn_id: int) -> SpaceTransaction:
    obj = db.scalar(
        select(SpaceTransaction).where(SpaceTransaction.id == txn_id, SpaceTransaction.space_id == space_id)
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[SpaceTransactionResponse])
def list_space_transactions(
    space: SpaceDep,
    db: DbDep,
    start_date: date | None = None,
    end_date: date | None = None,
):
    c = get_current_cycle(space.base_day)
    cycle_start = start_date if start_date is not None else c.start
    cycle_end = end_date if end_date is not None else c.end

    materialize_space_scheduled_items(db, space.id, cycle_start, cycle_end)

    q = select(SpaceTransaction).where(
        SpaceTransaction.space_id == space.id,
        SpaceTransaction.transaction_date >= cycle_start,
        SpaceTransaction.transaction_date <= cycle_end,
        SpaceTransaction.is_excluded.is_(False),
    )
    return db.scalars(q.order_by(SpaceTransaction.transaction_date.desc())).all()


@router.post("", response_model=SpaceTransactionResponse, status_code=status.HTTP_201_CREATED)
def create_space_transaction(body: SpaceTransactionCreate, space: SpaceDep, db: DbDep, user: UserDep):
    obj = SpaceTransaction(
        space_id=space.id,
        created_by_user_id=user.id,
        name=body.name,
        amount=body.amount,
        category_id=body.category_id,
        payment_method=body.payment_method,
        transaction_date=body.transaction_date,
        billing_date=body.transaction_date,
        memo=body.memo,
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{txn_id}", response_model=SpaceTransactionResponse)
def get_space_transaction(txn_id: int, space: SpaceDep, db: DbDep):
    return _get_or_404(db, space.id, txn_id)


@router.patch("/{txn_id}", response_model=SpaceTransactionResponse)
def patch_space_transaction(txn_id: int, body: SpaceTransactionPatch, space: SpaceDep, db: DbDep):
    obj = _get_or_404(db, space.id, txn_id)
    fields = body.model_dump(exclude_unset=True)

    if "transaction_date" in fields:
        obj.transaction_date = fields.pop("transaction_date")
        obj.billing_date = obj.transaction_date  # Space는 카드 청구일 계산 없음

    for field, value in fields.items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{txn_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_space_transaction(txn_id: int, space: SpaceDep, db: DbDep):
    obj = _get_or_404(db, space.id, txn_id)
    if obj.source_income_id is not None or obj.source_fixed_expense_id is not None:
        obj.is_excluded = True
        db.commit()
    else:
        db.delete(obj)
        db.commit()
