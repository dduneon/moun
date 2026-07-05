from __future__ import annotations

import enum
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Index, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.income import Frequency

if TYPE_CHECKING:
    pass


class SpacePaymentMethod(str, enum.Enum):
    """Space 거래는 카드 결제(청구일 계산)를 지원하지 않는다 — 현금/계좌만."""

    cash = "cash"
    account = "account"


class SpaceCategory(Base):
    __tablename__ = "space_category"

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    name: Mapped[str] = mapped_column(String(50))
    icon: Mapped[str | None] = mapped_column(String(10))


class SpaceIncome(Base):
    __tablename__ = "space_income"

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))
    name: Mapped[str] = mapped_column(String(100))
    frequency: Mapped[Frequency] = mapped_column(Enum(Frequency), default=Frequency.monthly)
    scheduled_day: Mapped[int | None]
    day_of_week: Mapped[int | None]
    expected_amount: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    category_id: Mapped[int | None] = mapped_column(ForeignKey("space_category.id"), nullable=True)
    group_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    effective_from: Mapped[date] = mapped_column(Date, default=date(2000, 1, 1))
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    category: Mapped[SpaceCategory | None] = relationship(foreign_keys=[category_id])


class SpaceFixedExpense(Base):
    __tablename__ = "space_fixed_expense"

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))
    name: Mapped[str] = mapped_column(String(100))
    amount: Mapped[Decimal] = mapped_column(Numeric(15, 2))
    payment_method: Mapped[SpacePaymentMethod] = mapped_column(Enum(SpacePaymentMethod))
    frequency: Mapped[Frequency] = mapped_column(Enum(Frequency), default=Frequency.monthly)
    billing_day: Mapped[int | None]
    day_of_week: Mapped[int | None]
    category_id: Mapped[int | None] = mapped_column(ForeignKey("space_category.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    group_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    effective_from: Mapped[date] = mapped_column(Date, default=date(2000, 1, 1))
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    category: Mapped[SpaceCategory | None] = relationship(foreign_keys=[category_id])


class SpaceTransaction(Base):
    __tablename__ = "space_transaction"
    __table_args__ = (
        Index("ix_space_transaction_space_date", "space_id", "transaction_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))
    amount: Mapped[Decimal] = mapped_column(Numeric(15, 2))
    category_id: Mapped[int] = mapped_column(ForeignKey("space_category.id"))
    payment_method: Mapped[SpacePaymentMethod] = mapped_column(Enum(SpacePaymentMethod))
    transaction_date: Mapped[date]
    billing_date: Mapped[date]
    name: Mapped[str | None] = mapped_column(String(200))
    memo: Mapped[str | None] = mapped_column(Text)
    receipt_image_url: Mapped[str | None] = mapped_column(String(500))
    source_income_id: Mapped[int | None] = mapped_column(ForeignKey("space_income.id"), nullable=True)
    source_fixed_expense_id: Mapped[int | None] = mapped_column(ForeignKey("space_fixed_expense.id"), nullable=True)
    is_excluded: Mapped[bool] = mapped_column(Boolean, server_default="0", default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    category: Mapped[SpaceCategory] = relationship(foreign_keys=[category_id])
    source_income: Mapped[SpaceIncome | None] = relationship(foreign_keys=[source_income_id])
    source_fixed_expense: Mapped[SpaceFixedExpense | None] = relationship(foreign_keys=[source_fixed_expense_id])
