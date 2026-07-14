from datetime import date
from decimal import Decimal

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.billing import calculate_billing_date
from app.core.budget_cycle import get_current_cycle
from app.core.deps import DbDep, UserDep
from app.core.schedule_generator import materialize_scheduled_items
from app.api.vouchers import voucher_balance
from app.models.card import Card
from app.models.fixed_expense import PaymentMethod
from app.models.transaction import Transaction
from app.models.voucher import Voucher
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

    # 상품권 결제는 잔액을 넘길 수 없다 → 잔액만큼만 상품권으로, 초과분은 현금으로
    # 자동 분할한다. (잔액이 음수가 되는 것을 근본적으로 방지)
    if body.payment_method == PaymentMethod.voucher:
        return _create_voucher_expense(db, user, body)

    billing_date = calculate_billing_date(body.transaction_date, body.payment_method, card)

    obj = Transaction(
        user_id=user.id,
        name=body.name,
        amount=body.amount,
        type=body.type,
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


def _create_voucher_expense(db, user, body: TransactionCreate) -> Transaction:
    """상품권 지출을 잔액 한도 내에서 처리. 잔액을 초과하면 초과분은 현금 거래로 분할.

    - amount는 지출이라 음수. spend = -amount(양수)가 결제 총액.
    - voucher_part = min(spend, 잔액) 만큼 상품권에서 차감(voucher_delta 음수).
    - 나머지 cash_part는 현금 거래로 별도 기록.
    반환값은 대표 거래(상품권 부분이 있으면 그것, 없으면 현금 부분)."""
    if body.voucher_id is None:
        raise HTTPException(status_code=422, detail="상품권 결제 시 voucher_id가 필요합니다")
    voucher = db.scalar(
        select(Voucher).where(Voucher.id == body.voucher_id, Voucher.user_id == user.id)
    )
    if not voucher:
        raise HTTPException(status_code=404, detail="Not found")

    balance = voucher_balance(db, voucher.id)
    if balance < 0:
        balance = Decimal(0)
    spend = -body.amount  # 양수 결제 총액
    billing_date = calculate_billing_date(body.transaction_date, PaymentMethod.voucher, None)

    voucher_part = min(spend, balance)  # 상품권으로 낼 금액 (양수)
    cash_part = spend - voucher_part    # 잔액 초과분 (양수)

    primary: Transaction | None = None

    if voucher_part > 0:
        v_txn = Transaction(
            user_id=user.id, name=body.name, amount=-voucher_part,
            type=body.type, category_id=body.category_id,
            payment_method=PaymentMethod.voucher, voucher_id=voucher.id,
            voucher_delta=-voucher_part,
            transaction_date=body.transaction_date, billing_date=billing_date, memo=body.memo,
        )
        db.add(v_txn)
        primary = v_txn

    if cash_part > 0:
        c_txn = Transaction(
            user_id=user.id, name=body.name, amount=-cash_part,
            type=body.type, category_id=body.category_id,
            payment_method=PaymentMethod.cash,
            transaction_date=body.transaction_date, billing_date=billing_date, memo=body.memo,
        )
        db.add(c_txn)
        if primary is None:
            primary = c_txn

    # spend가 0 이하인 비정상 입력 방어 — 상품권 거래 하나로 처리
    if primary is None:
        primary = Transaction(
            user_id=user.id, name=body.name, amount=body.amount,
            type=body.type, category_id=body.category_id,
            payment_method=PaymentMethod.voucher, voucher_id=voucher.id,
            voucher_delta=body.amount,
            transaction_date=body.transaction_date, billing_date=billing_date, memo=body.memo,
        )
        db.add(primary)

    db.commit()
    db.refresh(primary)
    return primary


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
        if obj.payment_method == PaymentMethod.card and card is None:
            # 카드 결제인데 카드 정보가 유실된(손상된) 항목 → 거래일을 청구일로 사용
            obj.billing_date = obj.transaction_date
        else:
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
