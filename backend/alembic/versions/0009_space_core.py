"""space core tables: space, space_member, space_invite

Revision ID: 0009
Revises: 0008
Create Date: 2026-07-03
"""
import sqlalchemy as sa
from alembic import op

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "space",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("base_day", sa.Integer, nullable=False, server_default="1"),
        sa.Column("created_by_user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )

    op.create_table(
        "space_member",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("joined_at", sa.DateTime, server_default=sa.func.now()),
    )
    op.create_index("ix_space_member_space_id", "space_member", ["space_id"])
    op.create_index("ix_space_member_user_id", "space_member", ["user_id"])
    op.create_index(
        "uq_space_member_space_user", "space_member", ["space_id", "user_id"], unique=True
    )

    op.create_table(
        "space_invite",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("space_id", sa.Integer, sa.ForeignKey("space.id"), nullable=False),
        sa.Column("token", sa.String(64), nullable=False),
        sa.Column("created_by_user_id", sa.Integer, sa.ForeignKey("user.id"), nullable=False),
        sa.Column("expires_at", sa.DateTime, nullable=False),
        sa.Column("max_uses", sa.Integer, nullable=True),
        sa.Column("use_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("revoked", sa.Boolean, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
    )
    op.create_index("ix_space_invite_space_id", "space_invite", ["space_id"])
    op.create_index("ix_space_invite_token", "space_invite", ["token"], unique=True)


def downgrade() -> None:
    op.drop_table("space_invite")
    op.drop_table("space_member")
    op.drop_table("space")
