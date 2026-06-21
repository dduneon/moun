"""remove budget_cycle table and cycle FK columns

Revision ID: 0006
Revises: 0005
Create Date: 2026-06-21
"""
from alembic import op
import sqlalchemy as sa

revision = '0006'
down_revision = '0005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # income: budget_cycle_id 컬럼에 걸린 FK 모두 제거 후 컬럼 삭제
    fk_names = conn.execute(sa.text(
        "SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'income' "
        "AND COLUMN_NAME = 'budget_cycle_id' AND REFERENCED_TABLE_NAME IS NOT NULL"
    )).scalars().all()
    for fk in fk_names:
        conn.execute(sa.text(f'ALTER TABLE `income` DROP FOREIGN KEY `{fk}`'))

    col_exists = conn.execute(sa.text(
        "SELECT COUNT(*) FROM information_schema.COLUMNS "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'income' AND COLUMN_NAME = 'budget_cycle_id'"
    )).scalar()
    if col_exists:
        conn.execute(sa.text('ALTER TABLE `income` DROP COLUMN `budget_cycle_id`'))

    # transaction: 인덱스 → 컬럼
    for idx in ('spend_cycle_id', 'billing_cycle_id'):
        idx_exists = conn.execute(sa.text(
            f"SELECT COUNT(*) FROM information_schema.STATISTICS "
            f"WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transaction' AND INDEX_NAME = '{idx}'"
        )).scalar()
        if idx_exists:
            conn.execute(sa.text(f'ALTER TABLE `transaction` DROP INDEX `{idx}`'))

    for col in ('spend_cycle_id', 'billing_cycle_id'):
        col_exists = conn.execute(sa.text(
            f"SELECT COUNT(*) FROM information_schema.COLUMNS "
            f"WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transaction' AND COLUMN_NAME = '{col}'"
        )).scalar()
        if col_exists:
            conn.execute(sa.text(f'ALTER TABLE `transaction` DROP COLUMN `{col}`'))

    # budget_cycle 테이블 삭제
    conn.execute(sa.text('DROP TABLE IF EXISTS `budget_cycle`'))


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text('''
        CREATE TABLE `budget_cycle` (
            `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT NOT NULL,
            `start_date` DATE NOT NULL,
            `end_date` DATE NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
        )
    '''))
    conn.execute(sa.text('ALTER TABLE `income` ADD COLUMN `budget_cycle_id` INT NULL'))
    conn.execute(sa.text('ALTER TABLE `income` ADD CONSTRAINT `income_ibfk_2` FOREIGN KEY (`budget_cycle_id`) REFERENCES `budget_cycle`(`id`)'))
    conn.execute(sa.text('ALTER TABLE `transaction` ADD COLUMN `spend_cycle_id` INT NOT NULL'))
    conn.execute(sa.text('ALTER TABLE `transaction` ADD COLUMN `billing_cycle_id` INT NOT NULL'))
    conn.execute(sa.text('ALTER TABLE `transaction` ADD CONSTRAINT `transaction_ibfk_4` FOREIGN KEY (`spend_cycle_id`) REFERENCES `budget_cycle`(`id`)'))
    conn.execute(sa.text('ALTER TABLE `transaction` ADD CONSTRAINT `transaction_ibfk_5` FOREIGN KEY (`billing_cycle_id`) REFERENCES `budget_cycle`(`id`)'))
    conn.execute(sa.text('CREATE INDEX `ix_transaction_user_spend_cycle` ON `transaction`(`user_id`, `spend_cycle_id`)'))
    conn.execute(sa.text('CREATE INDEX `ix_transaction_user_billing_cycle` ON `transaction`(`user_id`, `billing_cycle_id`)'))
