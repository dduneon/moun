"""add scheduled_day to income

Revision ID: 0005
Revises: 0004
Create Date: 2026-06-20
"""
from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("income", sa.Column("scheduled_day", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("income", "scheduled_day")
