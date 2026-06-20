from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class UserSetting(Base):
    """사용자별 가계부 설정."""

    __tablename__ = "user_setting"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), unique=True)

    # 예산 사이클 기준일: 매월 며칠이 월급날인지 (1~28, 말일은 28로 통일)
    salary_day: Mapped[int] = mapped_column(default=21)

    # 주말/공휴일일 때 실제 입금 처리 방식
    # 'prev_business': 이전 영업일 (대부분 회사)
    # 'next_business': 다음 영업일
    # 'exact': 그대로 (이체 없음)
    payday_adjustment: Mapped[str] = mapped_column(String(20), default="prev_business")

    # 공휴일 기준 국가 코드 (holidays 라이브러리 키)
    holiday_country: Mapped[str] = mapped_column(String(10), default="KR")

    user: Mapped[User] = relationship(back_populates="setting")
