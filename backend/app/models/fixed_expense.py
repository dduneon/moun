from __future__ import annotations

import enum
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.income import Frequency

if TYPE_CHECKING:
    from app.models.card import Card
    from app.models.category import Category
    from app.models.user import User


class PaymentMethod(str, enum.Enum):
    card = "card"
    cash = "cash"
    account = "account"


class FixedExpense(Base):
    __tablename__ = "fixed_expense"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    name: Mapped[str] = mapped_column(String(100))
    amount: Mapped[Decimal] = mapped_column(Numeric(15, 2))
    payment_method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod))
    frequency: Mapped[Frequency] = mapped_column(Enum(Frequency), default=Frequency.monthly)
    billing_day: Mapped[int | None]        # monthly: 1~31 (31=말일), 나머지: None
    day_of_week: Mapped[int | None]        # weekly/biweekly: 0=월~6=일, 나머지: None
    card_id: Mapped[int | None] = mapped_column(ForeignKey("card.id"), nullable=True)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("category.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    group_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    effective_from: Mapped[date] = mapped_column(Date, default=date(2000, 1, 1))
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped[User] = relationship(back_populates="fixed_expenses")
    card: Mapped[Card | None] = relationship(foreign_keys=[card_id])
    category: Mapped[Category | None] = relationship(foreign_keys=[category_id])
