"""add frequency and day_of_week to income and fixed_expense; make billing_day nullable

Revision ID: 0006
Revises: 0005
Create Date: 2026-06-25
"""
from alembic import op
import sqlalchemy as sa

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None

_frequency_enum = sa.Enum("monthly", "weekly", "biweekly", "daily", name="frequency")


def upgrade():
    # income
    _frequency_enum.create(op.get_bind(), checkfirst=True)
    op.add_column("income", sa.Column("frequency", _frequency_enum, nullable=False, server_default="monthly"))
    op.add_column("income", sa.Column("day_of_week", sa.Integer(), nullable=True))

    # fixed_expense: frequency, day_of_week 추가 + billing_day nullable 변경
    op.add_column("fixed_expense", sa.Column("frequency", _frequency_enum, nullable=False, server_default="monthly"))
    op.add_column("fixed_expense", sa.Column("day_of_week", sa.Integer(), nullable=True))
    op.alter_column("fixed_expense", "billing_day", existing_type=sa.Integer(), nullable=True)


def downgrade():
    op.alter_column("fixed_expense", "billing_day", existing_type=sa.Integer(), nullable=False)
    op.drop_column("fixed_expense", "day_of_week")
    op.drop_column("fixed_expense", "frequency")
    op.drop_column("income", "day_of_week")
    op.drop_column("income", "frequency")
    _frequency_enum.drop(op.get_bind(), checkfirst=True)
