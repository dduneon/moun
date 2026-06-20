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

    # income: FK → 컬럼
    conn.execute(sa.text('ALTER TABLE `income` DROP FOREIGN KEY `income_ibfk_2`'))
    conn.execute(sa.text('ALTER TABLE `income` DROP COLUMN `budget_cycle_id`'))

    # transaction: 남은 단순 인덱스 → 컬럼
    conn.execute(sa.text('ALTER TABLE `transaction` DROP INDEX `spend_cycle_id`'))
    conn.execute(sa.text('ALTER TABLE `transaction` DROP INDEX `billing_cycle_id`'))
    conn.execute(sa.text('ALTER TABLE `transaction` DROP COLUMN `spend_cycle_id`'))
    conn.execute(sa.text('ALTER TABLE `transaction` DROP COLUMN `billing_cycle_id`'))

    # budget_cycle 테이블 삭제
    conn.execute(sa.text('DROP TABLE `budget_cycle`'))


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
