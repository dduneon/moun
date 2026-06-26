"""add is_excluded to transaction

Revision ID: 0007
Revises: 0006
Create Date: 2026-06-25
"""
from alembic import op
import sqlalchemy as sa

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "transaction",
        sa.Column("is_excluded", sa.Boolean(), nullable=False, server_default="0"),
    )


def downgrade():
    op.drop_column("transaction", "is_excluded")
