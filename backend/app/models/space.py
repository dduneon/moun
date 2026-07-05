from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Space(Base):
    """멤버들이 공동으로 지출/수입을 기록하는 공유 공간. 개인 공간과 완전히 독립."""

    __tablename__ = "space"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    base_day: Mapped[int] = mapped_column(Integer, default=1)  # 예산 사이클 기준일, 생성 후 불변
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    members: Mapped[list[SpaceMember]] = relationship(back_populates="space")


class SpaceMember(Base):
    __tablename__ = "space_member"
    __table_args__ = (UniqueConstraint("space_id", "user_id", name="uq_space_member_space_user"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    joined_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    space: Mapped[Space] = relationship(back_populates="members")


class SpaceInvite(Base):
    __tablename__ = "space_invite"

    id: Mapped[int] = mapped_column(primary_key=True)
    space_id: Mapped[int] = mapped_column(ForeignKey("space.id"), index=True)
    token: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"))
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    max_uses: Mapped[int | None] = mapped_column(Integer, nullable=True)
    use_count: Mapped[int] = mapped_column(Integer, default=0)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
