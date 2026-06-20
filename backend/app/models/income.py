from __future__ import annotations

import enum
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.budget_cycle import BudgetCycle
    from app.models.user import User


class IncomeType(str, enum.Enum):
    salary = "salary"
    extra = "extra"


class IncomeStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"


class Income(Base):
    __tablename__ = "income"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    type: Mapped[IncomeType] = mapped_column(Enum(IncomeType))
    name: Mapped[str] = mapped_column(String(100))
    expected_amount: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    actual_amount: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    scheduled_day: Mapped[int | None]
    received_date: Mapped[date | None]
    status: Mapped[IncomeStatus] = mapped_column(Enum(IncomeStatus), default=IncomeStatus.pending)
    budget_cycle_id: Mapped[int | None] = mapped_column(ForeignKey("budget_cycle.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped[User] = relationship(back_populates="incomes")
    budget_cycle: Mapped[BudgetCycle | None] = relationship(back_populates="incomes")
