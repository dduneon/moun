from __future__ import annotations

from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class CategoryAmount(BaseModel):
    category_id: int
    category_name: str
    total: Decimal


class SpendSummary(BaseModel):
    total_spend: Decimal
    by_category: list[CategoryAmount]


class BillingSummary(BaseModel):
    total_billing: Decimal
    by_category: list[CategoryAmount]


class SavingSummary(BaseModel):
    total_saving: Decimal
    by_category: list[CategoryAmount]


class CycleBoundsResponse(BaseModel):
    start_date: date
    end_date: date
    label: str


class AvailableBudget(BaseModel):
    start_date: date
    end_date: date
    label: str
    confirmed_income: Decimal
    expected_income: Decimal
    fixed_expense: Decimal           # 미청구 예정 고정지출
    confirmed_fixed_expense: Decimal  # 이미 실행된 고정지출 트랜잭션 합계
    billed_transactions: Decimal
    confirmed_saving: Decimal        # 이미 실행된 저축/이체 트랜잭션 합계
    pending_saving: Decimal          # 미청구 예정 고정저축
    available: Decimal
    spend_summary: SpendSummary
    billing_summary: BillingSummary
    saving_summary: SavingSummary
