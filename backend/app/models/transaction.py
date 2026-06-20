from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, ForeignKey, Index, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.fixed_expense import PaymentMethod

if TYPE_CHECKING:
    from app.models.budget_cycle import BudgetCycle
    from app.models.card import Card
    from app.models.category import Category


class Transaction(Base):
    __tablename__ = "transaction"
    __table_args__ = (
        Index("ix_transaction_spend_cycle_id", "spend_cycle_id"),
        Index("ix_transaction_billing_cycle_id", "billing_cycle_id"),
        Index("ix_transaction_transaction_date", "transaction_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(15, 2))
    category_id: Mapped[int] = mapped_column(ForeignKey("category.id"))
    payment_method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod))
    card_id: Mapped[int | None] = mapped_column(ForeignKey("card.id"))
    transaction_date: Mapped[date]
    billing_date: Mapped[date]
    spend_cycle_id: Mapped[int] = mapped_column(ForeignKey("budget_cycle.id"))
    billing_cycle_id: Mapped[int] = mapped_column(ForeignKey("budget_cycle.id"))
    memo: Mapped[str | None] = mapped_column(Text)
    receipt_image_url: Mapped[str | None] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    category: Mapped[Category] = relationship(back_populates="transactions")
    card: Mapped[Card | None] = relationship(back_populates="transactions")
    spend_cycle: Mapped[BudgetCycle] = relationship(
        foreign_keys=[spend_cycle_id], back_populates="spend_transactions"
    )
    billing_cycle: Mapped[BudgetCycle] = relationship(
        foreign_keys=[billing_cycle_id], back_populates="billing_transactions"
    )
