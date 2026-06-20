"""add user and multiuser fks

Revision ID: 0002
Revises: 0001
Create Date: 2026-06-20

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # user
    op.create_table(
        "user",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_user_email", "user", ["email"])

    # user_setting
    op.create_table(
        "user_setting",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("user.id"), nullable=False, unique=True),
        sa.Column("salary_day", sa.Integer(), nullable=False, server_default="21"),
        sa.Column("payday_adjustment", sa.String(20), nullable=False, server_default="prev_business"),
        sa.Column("holiday_country", sa.String(10), nullable=False, server_default="KR"),
    )

    # add user_id to existing tables
    for table in ("budget_cycle", "income", "fixed_expense", "card", "category", "transaction"):
        op.add_column(table, sa.Column("user_id", sa.Integer(), sa.ForeignKey("user.id"), nullable=True))
        op.create_index(f"ix_{table}_user_id", table, ["user_id"])

    # replace old transaction indexes with composite ones
    op.drop_index("ix_transaction_spend_cycle_id", "transaction")
    op.drop_index("ix_transaction_billing_cycle_id", "transaction")
    op.drop_index("ix_transaction_transaction_date", "transaction")
    op.create_index("ix_transaction_user_spend_cycle", "transaction", ["user_id", "spend_cycle_id"])
    op.create_index("ix_transaction_user_billing_cycle", "transaction", ["user_id", "billing_cycle_id"])
    op.create_index("ix_transaction_user_date", "transaction", ["user_id", "transaction_date"])

    # category: drop unique constraint on name (now scoped per user)
    op.drop_index("uq_category_name", table_name="category", if_exists=True)


def downgrade() -> None:
    op.create_index("ix_transaction_transaction_date", "transaction", ["transaction_date"])
    op.create_index("ix_transaction_billing_cycle_id", "transaction", ["billing_cycle_id"])
    op.create_index("ix_transaction_spend_cycle_id", "transaction", ["spend_cycle_id"])
    op.drop_index("ix_transaction_user_date", "transaction")
    op.drop_index("ix_transaction_user_billing_cycle", "transaction")
    op.drop_index("ix_transaction_user_spend_cycle", "transaction")

    for table in ("budget_cycle", "income", "fixed_expense", "card", "category", "transaction"):
        op.drop_index(f"ix_{table}_user_id", table)
        op.drop_column(table, "user_id")

    op.drop_table("user_setting")
    op.drop_table("user")
