"""add type column to fixed_expense (expense/saving)

Revision ID: 0012
Revises: 0011
Create Date: 2026-07-07
"""
import sqlalchemy as sa
from alembic import op

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None

fixed_expense_type = sa.Enum("expense", "saving", name="fixedexpensetype")


def upgrade() -> None:
    fixed_expense_type.create(op.get_bind(), checkfirst=True)
    op.add_column(
        "fixed_expense",
        sa.Column("type", fixed_expense_type, nullable=False, server_default="expense"),
    )


def downgrade() -> None:
    op.drop_column("fixed_expense", "type")
    fixed_expense_type.drop(op.get_bind(), checkfirst=True)
