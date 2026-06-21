"""add kakao_id to user

Revision ID: 0004
Revises: 0003
Create Date: 2026-06-21
"""
from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("user", sa.Column("kakao_id", sa.String(64), nullable=True))
    op.alter_column("user", "email", existing_type=sa.String(255), nullable=True)
    op.alter_column("user", "hashed_password", existing_type=sa.String(255), nullable=True)
    op.create_unique_constraint("uq_user_kakao_id", "user", ["kakao_id"])
    op.create_index("ix_user_kakao_id", "user", ["kakao_id"])


def downgrade():
    op.drop_index("ix_user_kakao_id", table_name="user")
    op.drop_constraint("uq_user_kakao_id", "user", type_="unique")
    op.alter_column("user", "hashed_password", existing_type=sa.String(255), nullable=False)
    op.alter_column("user", "email", existing_type=sa.String(255), nullable=False)
    op.drop_column("user", "kakao_id")
