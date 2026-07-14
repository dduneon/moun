from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.transaction import Transaction
    from app.models.user import User


class Voucher(Base):
    """지역화폐/온누리 상품권 등 선불 충전형 결제수단.

    잔액(balance)은 별도 컬럼으로 저장하지 않고, 연결된 트랜잭션의
    voucher_delta 합으로 파생 계산한다 (충전 = +액면가, 사용 = 음수 지출액).
    이렇게 하면 충전/사용/삭제 어느 경우에도 잔액이 어긋나지 않는다.
    """

    __tablename__ = "voucher"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    name: Mapped[str] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped[User] = relationship(back_populates="vouchers")
    transactions: Mapped[list[Transaction]] = relationship(back_populates="voucher")
