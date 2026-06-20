from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.transaction import Transaction


class Card(Base):
    __tablename__ = "card"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    statement_day: Mapped[int]
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    transactions: Mapped[list[Transaction]] = relationship(back_populates="card")
