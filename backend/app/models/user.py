from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.card import Card
    from app.models.category import Category
    from app.models.fixed_expense import FixedExpense
    from app.models.income import Income
    from app.models.space import SpaceMember
    from app.models.transaction import Transaction
    from app.models.voucher import Voucher


class User(Base):
    __tablename__ = "user"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    kakao_id: Mapped[str | None] = mapped_column(String(64), unique=True, index=True, nullable=True)
    name: Mapped[str] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    salary_day: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    incomes: Mapped[list[Income]] = relationship(back_populates="user")
    fixed_expenses: Mapped[list[FixedExpense]] = relationship(back_populates="user")
    cards: Mapped[list[Card]] = relationship(back_populates="user")
    categories: Mapped[list[Category]] = relationship(back_populates="user")
    transactions: Mapped[list[Transaction]] = relationship(back_populates="user")
    vouchers: Mapped[list[Voucher]] = relationship(back_populates="user")
    space_memberships: Mapped[list[SpaceMember]] = relationship()
