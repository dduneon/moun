"""Space 재무 데이터 CRUD 스키마. app/schemas/common.py의 Space 버전."""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel

from app.models.income import Frequency
from app.models.space_finance import SpacePaymentMethod


# ── Category ──────────────────────────────────────────────────────────────────

class SpaceCategoryCreate(BaseModel):
    name: str
    icon: Optional[str] = None


class SpaceCategoryResponse(BaseModel):
    id: int
    name: str
    icon: Optional[str]
    model_config = {"from_attributes": True}


# ── Income ────────────────────────────────────────────────────────────────────

class SpaceIncomeCreate(BaseModel):
    name: str
    frequency: Frequency = Frequency.monthly
    scheduled_day: Optional[int] = None
    day_of_week: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    include_current_cycle: bool = True


class SpaceIncomeResponse(BaseModel):
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
    created_by_user_id: int
    created_at: datetime
    model_config = {"from_attributes": True}


class SpaceIncomePatch(BaseModel):
    name: Optional[str] = None
    frequency: Optional[Frequency] = None
    scheduled_day: Optional[int] = None
    day_of_week: Optional[int] = None
    expected_amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    effective_from: Optional[date] = None


class SpaceIncomeDelete(BaseModel):
    end_from: Optional[date] = None


# ── FixedExpense ──────────────────────────────────────────────────────────────

class SpaceFixedExpenseCreate(BaseModel):
    name: str
    amount: Decimal
    payment_method: SpacePaymentMethod
    frequency: Frequency = Frequency.monthly
    billing_day: Optional[int] = None
    day_of_week: Optional[int] = None
    category_id: Optional[int] = None
    include_current_cycle: bool = True


class SpaceFixedExpenseResponse(BaseModel):
    id: int
    name: str
    amount: Decimal
    payment_method: SpacePaymentMethod
    frequency: Frequency
    billing_day: Optional[int]
    day_of_week: Optional[int]
    category_id: Optional[int]
    is_active: bool
    group_id: Optional[int]
    effective_from: date
    end_date: Optional[date]
    created_by_user_id: int
    created_at: datetime
    model_config = {"from_attributes": True}


class SpaceFixedExpensePatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    payment_method: Optional[SpacePaymentMethod] = None
    frequency: Optional[Frequency] = None
    billing_day: Optional[int] = None
    day_of_week: Optional[int] = None
    category_id: Optional[int] = None
    is_active: Optional[bool] = None
    effective_from: Optional[date] = None


class SpaceFixedExpenseDelete(BaseModel):
    end_from: Optional[date] = None


# ── Transaction ───────────────────────────────────────────────────────────────

class SpaceTransactionCreate(BaseModel):
    name: Optional[str] = None
    amount: Decimal
    category_id: int
    payment_method: SpacePaymentMethod
    transaction_date: date
    memo: Optional[str] = None


class SpaceTransactionResponse(BaseModel):
    id: int
    name: Optional[str]
    amount: Decimal
    category_id: int
    payment_method: SpacePaymentMethod
    transaction_date: date
    billing_date: date
    memo: Optional[str]
    receipt_image_url: Optional[str]
    source_income_id: Optional[int]
    source_fixed_expense_id: Optional[int]
    is_excluded: bool = False
    created_by_user_id: int
    created_at: datetime
    model_config = {"from_attributes": True}


class SpaceTransactionPatch(BaseModel):
    name: Optional[str] = None
    amount: Optional[Decimal] = None
    category_id: Optional[int] = None
    transaction_date: Optional[date] = None
    memo: Optional[str] = None
