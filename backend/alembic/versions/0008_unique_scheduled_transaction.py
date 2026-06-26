"""unique constraint on scheduled transaction dates to prevent race condition duplicates

Revision ID: 0008
Revises: 0007
Create Date: 2026-06-25
"""
from alembic import op

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 중복 행 제거: 같은 (source_income_id, transaction_date) 중 id가 가장 작은 것만 남김
    op.execute("""
        DELETE t1 FROM transaction t1
        INNER JOIN transaction t2
          ON t1.source_income_id = t2.source_income_id
         AND t1.transaction_date  = t2.transaction_date
         AND t1.id > t2.id
        WHERE t1.source_income_id IS NOT NULL
    """)

    # 같은 (source_fixed_expense_id, transaction_date) 중복 제거
    op.execute("""
        DELETE t1 FROM transaction t1
        INNER JOIN transaction t2
          ON t1.source_fixed_expense_id = t2.source_fixed_expense_id
         AND t1.transaction_date         = t2.transaction_date
         AND t1.id > t2.id
        WHERE t1.source_fixed_expense_id IS NOT NULL
    """)

    op.create_index(
        "uq_transaction_income_date",
        "transaction",
        ["source_income_id", "transaction_date"],
        unique=True,
    )
    op.create_index(
        "uq_transaction_expense_date",
        "transaction",
        ["source_fixed_expense_id", "transaction_date"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uq_transaction_income_date", table_name="transaction")
    op.drop_index("uq_transaction_expense_date", table_name="transaction")
