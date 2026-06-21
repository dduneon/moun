from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class Income(Base):
    __tablename__ = "income"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    name: Mapped[str] = mapped_column(String(100))
    scheduled_day: Mapped[int | None]
    expected_amount: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    actual_amount: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    received_date: Mapped[date | None]
    group_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    effective_from: Mapped[date] = mapped_column(Date, default=date(2000, 1, 1))
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped[User] = relationship(back_populates="incomes")
