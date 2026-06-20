from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.income import Income
    from app.models.transaction import Transaction
    from app.models.user import User


class BudgetCycle(Base):
    __tablename__ = "budget_cycle"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    start_date: Mapped[date]
    end_date: Mapped[date]
    label: Mapped[str] = mapped_column(String(50))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped[User] = relationship(back_populates="budget_cycles")
    incomes: Mapped[list[Income]] = relationship(back_populates="budget_cycle")
    spend_transactions: Mapped[list[Transaction]] = relationship(
        foreign_keys="Transaction.spend_cycle_id", back_populates="spend_cycle"
    )
    billing_transactions: Mapped[list[Transaction]] = relationship(
        foreign_keys="Transaction.billing_cycle_id", back_populates="billing_cycle"
    )
