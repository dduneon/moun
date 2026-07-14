"""add voucher table + voucher payment method

Revision ID: 0013
Revises: 0012
Create Date: 2026-07-14
"""
import sqlalchemy as sa
from alembic import op

revision = "0013"
down_revision = "0012"
branch_labels = None
depends_on = None

_old_methods = sa.Enum("card", "cash", "account", name="paymentmethod")
_new_methods = sa.Enum("card", "cash", "account", "voucher", name="paymentmethod")


def upgrade() -> None:
    op.create_table(
        "voucher",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("user.id"), nullable=False, index=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # paymentmethod ENUM에 'voucher' 값 추가 (컬럼별로 MODIFY)
    op.alter_column(
        "transaction", "payment_method",
        existing_type=_old_methods, type_=_new_methods, existing_nullable=False,
    )
    op.alter_column(
        "fixed_expense", "payment_method",
        existing_type=_old_methods, type_=_new_methods, existing_nullable=False,
    )

    op.add_column("transaction", sa.Column("voucher_id", sa.Integer(), sa.ForeignKey("voucher.id"), nullable=True))
    op.add_column("transaction", sa.Column("voucher_delta", sa.Numeric(15, 2), nullable=True))


def downgrade() -> None:
    op.drop_column("transaction", "voucher_delta")
    op.drop_column("transaction", "voucher_id")

    op.alter_column(
        "fixed_expense", "payment_method",
        existing_type=_new_methods, type_=_old_methods, existing_nullable=False,
    )
    op.alter_column(
        "transaction", "payment_method",
        existing_type=_new_methods, type_=_old_methods, existing_nullable=False,
    )

    op.drop_table("voucher")
