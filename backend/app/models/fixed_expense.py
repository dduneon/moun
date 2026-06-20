from __future__ import annotations

import enum
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PaymentMethod(str, enum.Enum):
    card = "card"
    cash = "cash"
    account = "account"


class FixedExpense(Base):
    __tablename__ = "fixed_expense"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    amount: Mapped[Decimal] = mapped_column(Numeric(15, 2))
    payment_method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod))
    billing_day: Mapped[int]
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
