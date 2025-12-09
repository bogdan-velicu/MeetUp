"""add_fcm_token_to_users

Revision ID: 5762b0b0b451
Revises: aab99b69ca25
Create Date: 2025-12-09 20:45:24.830675

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '5762b0b0b451'
down_revision = 'aab99b69ca25'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('fcm_token', sa.String(255), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'fcm_token')

