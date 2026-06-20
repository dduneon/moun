from __future__ import annotations

from decimal import Decimal

from pydantic import BaseModel


class CategoryAmount(BaseModel):
    category_id: int
    category_name: str
    total: Decimal


class SpendSummary(BaseModel):
    """spend_cycle 기준 — 내가 얼마 썼는지 (거래일 기준)."""
    cycle_id: int
    total_spend: Decimal
    by_category: list[CategoryAmount]


class BillingSummary(BaseModel):
    """billing_cycle 기준 — 통장에서 얼마 빠지는지 (청구일 기준)."""
    cycle_id: int
    total_billing: Decimal
    by_category: list[CategoryAmount]


class AvailableBudget(BaseModel):
    cycle_id: int
    total_income: Decimal
    fixed_expense: Decimal
    billed_transactions: Decimal
    available: Decimal             # total_income - fixed_expense - billed_transactions
    spend_summary: SpendSummary
    billing_summary: BillingSummary
