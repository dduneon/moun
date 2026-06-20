"""remove salary fields

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
    op.drop_column("budget_cycle", "salary_expected")
    op.drop_column("budget_cycle", "salary_actual")

    op.drop_column("income", "type")
    op.drop_column("income", "scheduled_day")
    op.drop_column("income", "status")

    op.drop_table("user_setting")


def downgrade() -> None:
    op.create_table(
        "user_setting",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("user.id"), unique=True, nullable=False),
        sa.Column("salary_day", sa.Integer(), nullable=False, server_default="21"),
        sa.Column("payday_adjustment", sa.String(20), nullable=False, server_default="prev_business"),
        sa.Column("holiday_country", sa.String(10), nullable=False, server_default="KR"),
    )

    op.add_column("income", sa.Column("type", sa.String(20), nullable=True))
    op.add_column("income", sa.Column("scheduled_day", sa.Integer(), nullable=True))
    op.add_column("income", sa.Column("status", sa.String(20), nullable=True, server_default="pending"))

    op.add_column("budget_cycle", sa.Column("salary_expected", sa.Numeric(15, 2), nullable=True))
    op.add_column("budget_cycle", sa.Column("salary_actual", sa.Numeric(15, 2), nullable=True))
