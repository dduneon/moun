from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.billing import calculate_billing_date
from app.core.budget_cycle import get_cycle_for_date
from app.core.deps import DbDep, UserDep
from app.models.card import Card
from app.models.fixed_expense import PaymentMethod
from app.models.transaction import Transaction
from app.schemas.common import TransactionCreate, TransactionPatch, TransactionResponse

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _get_or_404(db, user_id: int, txn_id: int) -> Transaction:
    obj = db.scalar(select(Transaction).where(Transaction.id == txn_id, Transaction.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[TransactionResponse])
def list_transactions(
    db: DbDep,
    user: UserDep,
    spend_cycle_id: int | None = None,
    billing_cycle_id: int | None = None,
):
    q = select(Transaction).where(Transaction.user_id == user.id)
    if spend_cycle_id is not None:
        q = q.where(Transaction.spend_cycle_id == spend_cycle_id)
    if billing_cycle_id is not None:
        q = q.where(Transaction.billing_cycle_id == billing_cycle_id)
    return db.scalars(q.order_by(Transaction.transaction_date.desc())).all()


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(body: TransactionCreate, db: DbDep, user: UserDep):
    card = None
    if body.payment_method == PaymentMethod.card:
        if body.card_id is None:
            raise HTTPException(status_code=422, detail="카드 결제 시 card_id가 필요합니다")
        card = db.scalar(select(Card).where(Card.id == body.card_id, Card.user_id == user.id))
        if not card:
            raise HTTPException(status_code=404, detail="Not found")

    billing_date = calculate_billing_date(body.transaction_date, body.payment_method, card)
    spend_cycle = get_cycle_for_date(db, user.id, body.transaction_date)
    billing_cycle = get_cycle_for_date(db, user.id, billing_date)

    obj = Transaction(
        user_id=user.id,
        name=body.name,
        amount=body.amount,
        category_id=body.category_id,
        payment_method=body.payment_method,
        card_id=body.card_id,
        transaction_date=body.transaction_date,
        billing_date=billing_date,
        spend_cycle_id=spend_cycle.id,
        billing_cycle_id=billing_cycle.id,
        memo=body.memo,
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{txn_id}", response_model=TransactionResponse)
def get_transaction(txn_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, txn_id)


@router.patch("/{txn_id}", response_model=TransactionResponse)
def patch_transaction(txn_id: int, body: TransactionPatch, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, txn_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{txn_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(txn_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, txn_id)
    db.delete(obj)
    db.commit()
