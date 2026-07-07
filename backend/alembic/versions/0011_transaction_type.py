"""add type column to transaction (income/expense/saving)

Revision ID: 0011
Revises: 0010
Create Date: 2026-07-07
"""
import sqlalchemy as sa
from alembic import op

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None

transaction_type = sa.Enum("income", "expense", "saving", name="transactiontype")


def upgrade() -> None:
    transaction_type.create(op.get_bind(), checkfirst=True)
    op.add_column(
        "transaction",
        sa.Column("type", transaction_type, nullable=False, server_default="expense"),
    )
    op.execute("UPDATE `transaction` SET type = 'income' WHERE amount > 0")


def downgrade() -> None:
    op.drop_column("transaction", "type")
    transaction_type.drop(op.get_bind(), checkfirst=True)
