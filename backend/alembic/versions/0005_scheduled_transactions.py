"""scheduled transactions: add source FKs to transaction; add category/card to income/fixed_expense; drop actual_amount/received_date from income

Revision ID: 0005
Revises: 0004
Create Date: 2026-06-24
"""
from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade():
    # transaction 테이블: 출처 FK 추가
    op.add_column("transaction", sa.Column("source_income_id", sa.Integer(), nullable=True))
    op.add_column("transaction", sa.Column("source_fixed_expense_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_transaction_source_income",
        "transaction", "income",
        ["source_income_id"], ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_transaction_source_fixed_expense",
        "transaction", "fixed_expense",
        ["source_fixed_expense_id"], ["id"],
        ondelete="SET NULL",
    )

    # income 테이블: actual_amount, received_date 제거 / category_id 추가
    op.drop_column("income", "actual_amount")
    op.drop_column("income", "received_date")
    op.add_column("income", sa.Column("category_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_income_category",
        "income", "category",
        ["category_id"], ["id"],
        ondelete="SET NULL",
    )

    # fixed_expense 테이블: category_id, card_id 추가
    op.add_column("fixed_expense", sa.Column("category_id", sa.Integer(), nullable=True))
    op.add_column("fixed_expense", sa.Column("card_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_fixed_expense_category",
        "fixed_expense", "category",
        ["category_id"], ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_fixed_expense_card",
        "fixed_expense", "card",
        ["card_id"], ["id"],
        ondelete="SET NULL",
    )


def downgrade():
    op.drop_constraint("fk_fixed_expense_card", "fixed_expense", type_="foreignkey")
    op.drop_constraint("fk_fixed_expense_category", "fixed_expense", type_="foreignkey")
    op.drop_column("fixed_expense", "card_id")
    op.drop_column("fixed_expense", "category_id")

    op.drop_constraint("fk_income_category", "income", type_="foreignkey")
    op.drop_column("income", "category_id")
    op.add_column("income", sa.Column("received_date", sa.Date(), nullable=True))
    op.add_column("income", sa.Column("actual_amount", sa.Numeric(15, 2), nullable=True))

    op.drop_constraint("fk_transaction_source_fixed_expense", "transaction", type_="foreignkey")
    op.drop_constraint("fk_transaction_source_income", "transaction", type_="foreignkey")
    op.drop_column("transaction", "source_fixed_expense_id")
    op.drop_column("transaction", "source_income_id")
