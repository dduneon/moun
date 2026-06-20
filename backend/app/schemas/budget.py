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
    fixed_expense: Decimal
    billed_transactions: Decimal
    available: Decimal
    spend_summary: SpendSummary
    billing_summary: BillingSummary
