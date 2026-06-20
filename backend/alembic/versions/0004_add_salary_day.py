"""add salary_day to user

Revision ID: 0004
Revises: 0003
Create Date: 2026-06-20
"""
from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("user", sa.Column("salary_day", sa.Integer(), nullable=False, server_default="1"))


def downgrade() -> None:
    op.drop_column("user", "salary_day")
