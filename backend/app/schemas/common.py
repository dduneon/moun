"""공통 CRUD 스키마."""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.models.fixed_expense import FixedExpenseType, PaymentMethod
from app.models.income import Frequency
from app.models.transaction import TransactionType


# ── Income ────────────────────────────────────────────────────────────────────

class IncomeCreate(BaseModel):
    name: str
    frequency: Frequency = Frequency.monthly
    scheduled_day: Optional[int] = None   # monthly용 (1~31)
    day_of_week: Optional[int] = None     # weekly/biweekly용 (0=월~6=일)
    expected_amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    include_current_cycle: bool = True


class IncomeResponse(BaseModel):
    id: int
    name: str
    frequency: Frequency
    scheduled_day: Optional[int]
    day_of_week: Optional[int]
    expected_amount: Optional[Decimal]
    category_id: Optional[int]
    group_id: Optional[int]
    effective_from: date
    end_date: Optional[date]
    created_at: datetime
    model_config = {"from_attributes": True}


class IncomePatch(BaseModel):
    name: Optional[str] = None
    frequency: Optional[Frequency] = None
    scheduled_day: Optional[int] = None
    day_of_week: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    effective_from: Optional[date] = None  # 새 버전 생성 시 지정


class IncomeDelete(BaseModel):
    end_from: Optional[date] = None  # None → 전체 삭제, date → 해당 월부터 소프트 삭제


# ── FixedExpense ──────────────────────────────────────────────────────────────

class FixedExpenseCreate(BaseModel):
    name: str
    amount: Decimal
    type: FixedExpenseType = FixedExpenseType.expense
    payment_method: PaymentMethod
    frequency: Frequency = Frequency.monthly
    billing_day: Optional[int] = None     # monthly용 (1~31)
    day_of_week: Optional[int] = None     # weekly/biweekly용 (0=월~6=일)
    card_id: Optional[int] = None
    category_id: Optional[int] = None
    include_current_cycle: bool = True


class FixedExpenseResponse(BaseModel):
    id: int
    name: str
    amount: Decimal
    type: FixedExpenseType
    payment_method: PaymentMethod
    frequency: Frequency
    billing_day: Optional[int]
    day_of_week: Optional[int]
    card_id: Optional[int]
    category_id: Optional[int]
    is_active: bool
    group_id: Optional[int]
    effective_from: date
    end_date: Optional[date]
    created_at: datetime
    model_config = {"from_attributes": True}


class FixedExpensePatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    type: Optional[FixedExpenseType] = None
    payment_method: Optional[PaymentMethod] = None
    frequency: Optional[Frequency] = None
    billing_day: Optional[int] = None
    day_of_week: Optional[int] = None
    card_id: Optional[int] = None
    category_id: Optional[int] = None
    is_active: Optional[bool] = None
    effective_from: Optional[date] = None  # 새 버전 생성 시 지정


class FixedExpenseDelete(BaseModel):
    end_from: Optional[date] = None  # None → 전체 삭제, date → 해당 월부터 소프트 삭제


# ── Card ──────────────────────────────────────────────────────────────────────

class CardCreate(BaseModel):
    name: str
    statement_day: int


class CardResponse(BaseModel):
    id: int
    name: str
    statement_day: int
    is_active: bool
    model_config = {"from_attributes": True}


class CardPatch(BaseModel):
    name: Optional[str] = None
    statement_day: Optional[int] = None
    is_active: Optional[bool] = None


# ── Voucher ───────────────────────────────────────────────────────────────────

class VoucherCreate(BaseModel):
    name: str


class VoucherResponse(BaseModel):
    id: int
    name: str
    is_active: bool
    balance: Decimal  # 연결 트랜잭션의 voucher_delta 합으로 파생 계산
    model_config = {"from_attributes": True}


class VoucherPatch(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None


class VoucherChargeRequest(BaseModel):
    """상품권 충전. 실제 지불액(paid_amount)만큼 가용 예산에서 차감되고,
    액면가(face_amount)만큼 상품권 잔액이 늘어난다. 할인 구매 시 둘이 다르다
    (예: 온누리 10% → paid 90,000 / face 100,000)."""
    paid_amount: Decimal            # 실제 계좌/카드에서 나간 금액 (양수)
    face_amount: Optional[Decimal] = None  # 충전된 액면가 (미지정 시 paid_amount와 동일 = 할인 없음)
    category_id: int
    transaction_date: date
    payment_method: PaymentMethod = PaymentMethod.account  # voucher 자기 자신은 불가
    card_id: Optional[int] = None
    name: Optional[str] = None
    memo: Optional[str] = None


# ── Transaction ───────────────────────────────────────────────────────────────

class TransactionCreate(BaseModel):
    name: Optional[str] = None
    amount: Decimal
    type: TransactionType = TransactionType.expense
    category_id: int
    payment_method: PaymentMethod
    card_id: Optional[int] = None
    voucher_id: Optional[int] = None  # payment_method == voucher 일 때 필수
    transaction_date: date
    memo: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    name: Optional[str]
    amount: Decimal
    type: TransactionType
    category_id: int
    payment_method: PaymentMethod
    card_id: Optional[int]
    voucher_id: Optional[int] = None
    transaction_date: date
    billing_date: date
    memo: Optional[str]
    receipt_image_url: Optional[str]
    source_income_id: Optional[int]
    source_fixed_expense_id: Optional[int]
    is_excluded: bool = False
    created_at: datetime
    model_config = {"from_attributes": True}


class TransactionPatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    type: Optional[TransactionType] = None
    category_id: Optional[int] = None
    transaction_date: Optional[date] = None
    memo: Optional[str] = None
