from datetime import date

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.billing import calculate_billing_date
from app.core.budget_cycle import get_current_cycle
from app.core.deps import DbDep, UserDep
from app.core.schedule_generator import materialize_scheduled_items
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
    c = get_current_cycle(user.salary_day)
    cycle_start = start_date if start_date is not None else c.start
    cycle_end = end_date if end_date is not None else c.end

    # 날짜가 지난 고정 수입/지출 → 자동으로 transaction 생성
    materialize_scheduled_items(db, user.id, cycle_start, cycle_end)

    q = select(Transaction).where(
        Transaction.user_id == user.id,
        Transaction.transaction_date >= cycle_start,
        Transaction.transaction_date <= cycle_end,
        Transaction.is_excluded.is_(False),
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
    fields = body.model_dump(exclude_unset=True)

    if "transaction_date" in fields:
        obj.transaction_date = fields.pop("transaction_date")
        card = db.scalar(select(Card).where(Card.id == obj.card_id)) if obj.card_id else None
        obj.billing_date = calculate_billing_date(obj.transaction_date, obj.payment_method, card)

    for field, value in fields.items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{txn_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(txn_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, txn_id)
    if obj.source_income_id is not None or obj.source_fixed_expense_id is not None:
        # 고정 수입/지출 자동 생성 항목 → soft-delete (재생성 방지)
        obj.is_excluded = True
        db.commit()
    else:
        db.delete(obj)
        db.commit()
