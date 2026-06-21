"""공통 CRUD 스키마."""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.models.fixed_expense import PaymentMethod


# ── Income ────────────────────────────────────────────────────────────────────

class IncomeCreate(BaseModel):
    name: str
    scheduled_day: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    actual_amount: Optional[Decimal] = None
    received_date: Optional[date] = None


class IncomeResponse(BaseModel):
    id: int
    name: str
    scheduled_day: Optional[int]
    expected_amount: Optional[Decimal]
    actual_amount: Optional[Decimal]
    received_date: Optional[date]
    group_id: Optional[int]
    effective_from: date
    end_date: Optional[date]
    created_at: datetime
    model_config = {"from_attributes": True}


class IncomePatch(BaseModel):
    name: Optional[str] = None
    scheduled_day: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    actual_amount: Optional[Decimal] = None
    received_date: Optional[date] = None
    effective_from: Optional[date] = None  # 새 버전 생성 시 지정


class IncomeDelete(BaseModel):
    end_from: Optional[date] = None  # None → 전체 삭제, date → 해당 월부터 소프트 삭제


# ── FixedExpense ──────────────────────────────────────────────────────────────

class FixedExpenseCreate(BaseModel):
    name: str
    amount: Decimal
    payment_method: PaymentMethod
    billing_day: int


class FixedExpenseResponse(BaseModel):
    id: int
    name: str
    amount: Decimal
    payment_method: PaymentMethod
    billing_day: int
    is_active: bool
    group_id: Optional[int]
    effective_from: date
    end_date: Optional[date]
    created_at: datetime
    model_config = {"from_attributes": True}


class FixedExpensePatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    payment_method: Optional[PaymentMethod] = None
    billing_day: Optional[int] = None
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


# ── Transaction ───────────────────────────────────────────────────────────────

class TransactionCreate(BaseModel):
    name: Optional[str] = None
    amount: Decimal
    category_id: int
    payment_method: PaymentMethod
    card_id: Optional[int] = None
    transaction_date: date
    memo: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    name: Optional[str]
    amount: Decimal
    category_id: int
    payment_method: PaymentMethod
    card_id: Optional[int]
    transaction_date: date
    billing_date: date
    memo: Optional[str]
    receipt_image_url: Optional[str]
    created_at: datetime
    model_config = {"from_attributes": True}


class TransactionPatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    memo: Optional[str] = None
