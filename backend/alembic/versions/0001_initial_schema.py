"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-06-21
"""
import sqlalchemy as sa
from alembic import op

revision = '0001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'user',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('email', sa.String(255), nullable=False, unique=True),
        sa.Column('hashed_password', sa.String(255), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='1'),
        sa.Column('salary_day', sa.Integer, nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('ix_user_email', 'user', ['email'], unique=True)

    op.create_table(
        'category',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id'), nullable=False),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('icon', sa.String(10), nullable=True),
    )
    op.create_index('ix_category_user_id', 'category', ['user_id'])

    op.create_table(
        'card',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id'), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('statement_day', sa.Integer, nullable=False),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='1'),
    )
    op.create_index('ix_card_user_id', 'card', ['user_id'])

    op.create_table(
        'income',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id'), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('scheduled_day', sa.Integer, nullable=True),
        sa.Column('expected_amount', sa.Numeric(15, 2), nullable=True),
        sa.Column('actual_amount', sa.Numeric(15, 2), nullable=True),
        sa.Column('received_date', sa.Date, nullable=True),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('ix_income_user_id', 'income', ['user_id'])

    op.create_table(
        'fixed_expense',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id'), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('amount', sa.Numeric(15, 2), nullable=False),
        sa.Column('payment_method', sa.Enum('card', 'cash', 'account'), nullable=False),
        sa.Column('billing_day', sa.Integer, nullable=False),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('ix_fixed_expense_user_id', 'fixed_expense', ['user_id'])

    op.create_table(
        'transaction',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('user.id'), nullable=False),
        sa.Column('amount', sa.Numeric(15, 2), nullable=False),
        sa.Column('category_id', sa.Integer, sa.ForeignKey('category.id'), nullable=False),
        sa.Column('payment_method', sa.Enum('card', 'cash', 'account'), nullable=False),
        sa.Column('card_id', sa.Integer, sa.ForeignKey('card.id'), nullable=True),
        sa.Column('transaction_date', sa.Date, nullable=False),
        sa.Column('billing_date', sa.Date, nullable=False),
        sa.Column('name', sa.String(200), nullable=True),
        sa.Column('memo', sa.Text, nullable=True),
        sa.Column('receipt_image_url', sa.String(500), nullable=True),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('ix_transaction_user_id', 'transaction', ['user_id'])
    op.create_index('ix_transaction_user_date', 'transaction', ['user_id', 'transaction_date'])


def downgrade() -> None:
    op.drop_table('transaction')
    op.drop_table('fixed_expense')
    op.drop_table('income')
    op.drop_table('card')
    op.drop_table('category')
    op.drop_table('user')
