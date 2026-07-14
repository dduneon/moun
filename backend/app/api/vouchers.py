from decimal import Decimal

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import func, select

from app.core.billing import calculate_billing_date
from app.core.deps import DbDep, UserDep
from app.core.schedule_generator import _get_or_create_system_category
from app.models.card import Card
from app.models.fixed_expense import PaymentMethod
from app.models.transaction import Transaction, TransactionType
from app.models.voucher import Voucher

# 충전 거래에 자동 지정되는 시스템 카테고리 (사용자가 직접 고르지 않음)
SYSTEM_VOUCHER_CATEGORY = "상품권 충전"
from app.schemas.common import (
    VoucherChargeRequest,
    VoucherCreate,
    VoucherPatch,
    VoucherResponse,
)

router = APIRouter(prefix="/vouchers", tags=["vouchers"])


def voucher_balance(db, voucher_id: int) -> Decimal:
    """상품권 잔액 = 연결된 (삭제되지 않은) 트랜잭션의 voucher_delta 합."""
    total = db.scalar(
        select(func.coalesce(func.sum(Transaction.voucher_delta), 0)).where(
            Transaction.voucher_id == voucher_id,
            Transaction.is_excluded.is_(False),
        )
    )
    return Decimal(str(total))


def _to_response(db, obj: Voucher) -> VoucherResponse:
    return VoucherResponse(
        id=obj.id,
        name=obj.name,
        is_active=obj.is_active,
        balance=voucher_balance(db, obj.id),
    )


def _get_or_404(db, user_id: int, voucher_id: int) -> Voucher:
    obj = db.scalar(select(Voucher).where(Voucher.id == voucher_id, Voucher.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[VoucherResponse])
def list_vouchers(db: DbDep, user: UserDep):
    rows = db.scalars(select(Voucher).where(Voucher.user_id == user.id)).all()
    return [_to_response(db, v) for v in rows]


@router.post("", response_model=VoucherResponse, status_code=status.HTTP_201_CREATED)
def create_voucher(body: VoucherCreate, db: DbDep, user: UserDep):
    obj = Voucher(user_id=user.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return _to_response(db, obj)


@router.get("/{voucher_id}", response_model=VoucherResponse)
def get_voucher(voucher_id: int, db: DbDep, user: UserDep):
    return _to_response(db, _get_or_404(db, user.id, voucher_id))


@router.patch("/{voucher_id}", response_model=VoucherResponse)
def patch_voucher(voucher_id: int, body: VoucherPatch, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, voucher_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return _to_response(db, obj)


@router.delete("/{voucher_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_voucher(voucher_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, voucher_id)
    db.delete(obj)
    db.commit()


@router.post("/{voucher_id}/charge", response_model=VoucherResponse, status_code=status.HTTP_201_CREATED)
def charge_voucher(voucher_id: int, body: VoucherChargeRequest, db: DbDep, user: UserDep):
    """상품권 충전. saving 타입 트랜잭션을 만들어 실지불액을 예산에서 차감하고,
    voucher_delta에 액면가를 기록해 잔액을 늘린다."""
    voucher = _get_or_404(db, user.id, voucher_id)

    if body.payment_method == PaymentMethod.voucher:
        raise HTTPException(status_code=422, detail="상품권 충전은 상품권으로 결제할 수 없습니다")
    if body.paid_amount <= 0:
        raise HTTPException(status_code=422, detail="paid_amount는 양수여야 합니다")

    face_amount = body.face_amount if body.face_amount is not None else body.paid_amount
    if face_amount <= 0:
        raise HTTPException(status_code=422, detail="face_amount는 양수여야 합니다")

    card = None
    if body.payment_method == PaymentMethod.card:
        if body.card_id is None:
            raise HTTPException(status_code=422, detail="카드 결제 시 card_id가 필요합니다")
        card = db.scalar(select(Card).where(Card.id == body.card_id, Card.user_id == user.id))
        if not card:
            raise HTTPException(status_code=404, detail="Not found")

    billing_date = calculate_billing_date(body.transaction_date, body.payment_method, card)

    # 분류는 사용자가 고르지 않고 "상품권 충전" 시스템 카테고리로 자동 지정.
    # (요청에 category_id가 오면 그대로 존중 — 향후 확장 여지)
    category_id = body.category_id or _get_or_create_system_category(
        db, user.id, SYSTEM_VOUCHER_CATEGORY
    )

    txn = Transaction(
        user_id=user.id,
        name=body.name or f"{voucher.name} 충전",
        amount=-body.paid_amount,          # 실제 계좌에서 나간 금액 (음수 = 예산 차감)
        type=TransactionType.saving,       # 소비 통계 제외, 가용 예산에서는 차감
        category_id=category_id,
        payment_method=body.payment_method,
        card_id=body.card_id,
        voucher_id=voucher.id,
        voucher_delta=face_amount,         # 잔액 증가분 (액면가)
        transaction_date=body.transaction_date,
        billing_date=billing_date,
        memo=body.memo,
    )
    db.add(txn)
    db.commit()
    return _to_response(db, voucher)
