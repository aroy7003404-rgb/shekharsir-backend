"""Add email verification and classroom recordings tables

Revision ID: e829103c842b
Revises: d44595205b31
Create Date: 2026-10-15 14:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e829103c842b'
down_revision: Union[str, Sequence[str], None] = 'd44595205b31'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # 1. Add email verification columns to users table
    op.add_column('users', sa.Column('is_email_verified', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('users', sa.Column('verification_code', sa.String(), nullable=True))

    # 2. Create classroom_recordings table linked to live_classrooms
    op.create_table(
        'classroom_recordings',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('classroom_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('file_type', sa.String(), server_default='Video', nullable=False),
        sa.Column('file_url', sa.String(), nullable=True),
        sa.Column('file_path', sa.String(), nullable=True),
        sa.Column('upload_date', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['classroom_id'], ['live_classrooms.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_classroom_recordings_id'), 'classroom_recordings', ['id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_classroom_recordings_id'), table_name='classroom_recordings')
    op.drop_table('classroom_recordings')
    op.drop_column('users', 'verification_code')
    op.drop_column('users', 'is_email_verified')
