"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-06-20

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "budget_cycle",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("label", sa.String(50), nullable=False),
        sa.Column("salary_expected", sa.Numeric(15, 2), nullable=False),
        sa.Column("salary_actual", sa.Numeric(15, 2), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
    )

    op.create_table(
        "income",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("type", sa.Enum("salary", "extra", name="incometype"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("expected_amount", sa.Numeric(15, 2), nullable=True),
        sa.Column("actual_amount", sa.Numeric(15, 2), nullable=True),
        sa.Column("scheduled_day", sa.Integer(), nullable=True),
        sa.Column("received_date", sa.Date(), nullable=True),
        sa.Column("status", sa.Enum("pending", "confirmed", name="incomestatus"), nullable=False, server_default="pending"),
        sa.Column("budget_cycle_id", sa.Integer(), sa.ForeignKey("budget_cycle.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
    )

    op.create_table(
        "fixed_expense",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("payment_method", sa.Enum("card", "cash", "account", name="paymentmethod"), nullable=False),
        sa.Column("billing_day", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
    )

    op.create_table(
        "card",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("statement_day", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
    )

    op.create_table(
        "category",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(50), nullable=False, unique=True),
        sa.Column("icon", sa.String(10), nullable=True),
    )

    op.create_table(
        "transaction",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("category.id"), nullable=False),
        sa.Column("payment_method", sa.Enum("card", "cash", "account", name="paymentmethod"), nullable=False),
        sa.Column("card_id", sa.Integer(), sa.ForeignKey("card.id"), nullable=True),
        sa.Column("transaction_date", sa.Date(), nullable=False),
        sa.Column("billing_date", sa.Date(), nullable=False),
        sa.Column("spend_cycle_id", sa.Integer(), sa.ForeignKey("budget_cycle.id"), nullable=False),
        sa.Column("billing_cycle_id", sa.Integer(), sa.ForeignKey("budget_cycle.id"), nullable=False),
        sa.Column("memo", sa.Text(), nullable=True),
        sa.Column("receipt_image_url", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
    )

    op.create_index("ix_transaction_spend_cycle_id", "transaction", ["spend_cycle_id"])
    op.create_index("ix_transaction_billing_cycle_id", "transaction", ["billing_cycle_id"])
    op.create_index("ix_transaction_transaction_date", "transaction", ["transaction_date"])


def downgrade() -> None:
    op.drop_index("ix_transaction_transaction_date", "transaction")
    op.drop_index("ix_transaction_billing_cycle_id", "transaction")
    op.drop_index("ix_transaction_spend_cycle_id", "transaction")
    op.drop_table("transaction")
    op.drop_table("category")
    op.drop_table("card")
    op.drop_table("fixed_expense")
    op.drop_table("income")
    op.drop_table("budget_cycle")
