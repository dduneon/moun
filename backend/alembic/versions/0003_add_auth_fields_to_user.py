"""add auth fields to user

Revision ID: 0003
Revises: 0002
Create Date: 2026-06-20

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("user", sa.Column("hashed_password", sa.String(255), nullable=True))
    op.add_column("user", sa.Column("name", sa.String(100), nullable=True))
    # nullable=True로 추가 후 기존 데이터 처리 완료 시 NOT NULL로 변경
    # (여기서는 새 스키마이므로 바로 NOT NULL 가능하나 마이그레이션 호환성을 위해 nullable)


def downgrade() -> None:
    op.drop_column("user", "name")
    op.drop_column("user", "hashed_password")
