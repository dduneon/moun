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
    created_at: datetime
    model_config = {"from_attributes": True}


class IncomePatch(BaseModel):
    name: Optional[str] = None
    scheduled_day: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    actual_amount: Optional[Decimal] = None
    received_date: Optional[date] = None


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
    created_at: datetime
    model_config = {"from_attributes": True}


class FixedExpensePatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    payment_method: Optional[PaymentMethod] = None
    billing_day: Optional[int] = None
    is_active: Optional[bool] = None


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
