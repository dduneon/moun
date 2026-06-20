from datetime import date

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.billing import calculate_billing_date
from app.core.budget_cycle import get_current_cycle
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
    start_date: date | None = None,
    end_date: date | None = None,
):
    q = select(Transaction).where(Transaction.user_id == user.id)
    if start_date is not None:
        q = q.where(Transaction.transaction_date >= start_date)
    if end_date is not None:
        q = q.where(Transaction.transaction_date <= end_date)
    # 날짜 미지정 시 현재 사이클 범위 기본값
    if start_date is None and end_date is None:
        c = get_current_cycle(user.salary_day)
        q = q.where(
            Transaction.transaction_date >= c.start,
            Transaction.transaction_date <= c.end,
        )
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

    obj = Transaction(
        user_id=user.id,
        name=body.name,
        amount=body.amount,
        category_id=body.category_id,
        payment_method=body.payment_method,
        card_id=body.card_id,
        transaction_date=body.transaction_date,
        billing_date=billing_date,
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
