"""add effective_from and group_id to fixed_expense and income

Revision ID: 0002
Revises: 0001
Create Date: 2026-06-21
"""
from datetime import date

from alembic import op
import sqlalchemy as sa

revision = '0002'
down_revision = '0001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('fixed_expense',
        sa.Column('group_id', sa.Integer(), nullable=True, index=True))
    op.add_column('fixed_expense',
        sa.Column('effective_from', sa.Date(), nullable=False, server_default='2000-01-01'))

    op.add_column('income',
        sa.Column('group_id', sa.Integer(), nullable=True, index=True))
    op.add_column('income',
        sa.Column('effective_from', sa.Date(), nullable=False, server_default='2000-01-01'))

    # 기존 데이터: group_id를 자기 자신의 id로 설정
    op.execute("UPDATE fixed_expense SET group_id = id WHERE group_id IS NULL")
    op.execute("UPDATE income SET group_id = id WHERE group_id IS NULL")


def downgrade() -> None:
    op.drop_column('fixed_expense', 'effective_from')
    op.drop_column('fixed_expense', 'group_id')
    op.drop_column('income', 'effective_from')
    op.drop_column('income', 'group_id')
