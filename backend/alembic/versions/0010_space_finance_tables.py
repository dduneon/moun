"""space finance tables: space_category, space_income, space_fixed_expense, space_transaction

Revision ID: 0010
Revises: 0009
Create Date: 2026-07-03
"""
import sqlalchemy as sa
from alembic import op

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "space_category",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("icon", sa.String(10), nullable=True),
    )
    op.create_index("ix_space_category_space_id", "space_category", ["space_id"])

    op.create_table(
        "space_income",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("frequency", sa.Enum("monthly", "weekly", "biweekly", "daily"), nullable=False, server_default="monthly"),
        sa.Column("scheduled_day", sa.Integer, nullable=True),
        sa.Column("day_of_week", sa.Integer, nullable=True),
        sa.Column("expected_amount", sa.Numeric(15, 2), nullable=True),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("space_category.id"), nullable=True),
        sa.Column("group_id", sa.Integer, nullable=True),
        sa.Column("effective_from", sa.Date, nullable=False, server_default="2000-01-01"),
        sa.Column("end_date", sa.Date, nullable=True),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index("ix_space_income_space_id", "space_income", ["space_id"])
    op.create_index("ix_space_income_group_id", "space_income", ["group_id"])

    op.create_table(
        "space_fixed_expense",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("payment_method", sa.Enum("cash", "account"), nullable=False),
        sa.Column("frequency", sa.Enum("monthly", "weekly", "biweekly", "daily"), nullable=False, server_default="monthly"),
        sa.Column("billing_day", sa.Integer, nullable=True),
        sa.Column("day_of_week", sa.Integer, nullable=True),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("space_category.id"), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="1"),
        sa.Column("group_id", sa.Integer, nullable=True),
        sa.Column("effective_from", sa.Date, nullable=False, server_default="2000-01-01"),
        sa.Column("end_date", sa.Date, nullable=True),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index("ix_space_fixed_expense_space_id", "space_fixed_expense", ["space_id"])
    op.create_index("ix_space_fixed_expense_group_id", "space_fixed_expense", ["group_id"])

    op.create_table(
        "space_transaction",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("space_category.id"), nullable=False),
        sa.Column("payment_method", sa.Enum("cash", "account"), nullable=False),
        sa.Column("transaction_date", sa.Date, nullable=False),
        sa.Column("billing_date", sa.Date, nullable=False),
        sa.Column("name", sa.String(200), nullable=True),
        sa.Column("memo", sa.Text, nullable=True),
        sa.Column("receipt_image_url", sa.String(500), nullable=True),
        sa.Column("source_income_id", sa.Integer, sa.ForeignKey("space_income.id"), nullable=True),
        sa.Column("source_fixed_expense_id", sa.Integer, sa.ForeignKey("space_fixed_expense.id"), nullable=True),
        sa.Column("is_excluded", sa.Boolean, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index("ix_space_transaction_space_id", "space_transaction", ["space_id"])
    op.create_index("ix_space_transaction_space_date", "space_transaction", ["space_id", "transaction_date"])
    op.create_index(
        "uq_space_transaction_income_date",
        "space_transaction",
        ["source_income_id", "transaction_date"],
        unique=True,
    )
    op.create_index(
        "uq_space_transaction_expense_date",
        "space_transaction",
        ["source_fixed_expense_id", "transaction_date"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_table("space_transaction")
    op.drop_table("space_fixed_expense")
    op.drop_table("space_income")
    op.drop_table("space_category")
