"""Initial schema — all tables.

Revision ID: 0001
Revises:
Create Date: 2024-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'organizations',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('name', sa.String(200), nullable=False),
        sa.Column('is_demo', sa.Boolean(), server_default='true'),
        sa.Column('is_showcase', sa.Boolean(), server_default='false'),  # permanent org, images never deleted
        sa.Column('settings', postgresql.JSONB(), server_default='{}'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        'guest_accounts',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(320), unique=True, nullable=False),
        sa.Column('key_hash', sa.String(256), nullable=False),
        sa.Column('org_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('organizations.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
    )

    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('org_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('username', sa.String(80), nullable=False),
        sa.Column('password_hash', sa.String(256), nullable=False),
        sa.Column('role', sa.String(20), nullable=False),
        sa.Column('full_name', sa.String(200), nullable=True),
        sa.Column('email', sa.String(320), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.Column('manager_key_hash', sa.String(256), nullable=True),  # only for managers
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('org_id', 'username', name='uq_users_org_username'),
    )

    op.create_table(
        'face_data',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True),
        sa.Column('encrypted_embedding', sa.Text(), nullable=False),
        sa.Column('image_path', sa.String(500), nullable=True),   # local filesystem path
        sa.Column('is_permanent', sa.Boolean(), server_default='false'),  # permanent → never cleaned up
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        'attendance_records',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE')),
        sa.Column('org_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('organizations.id')),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('check_in', sa.DateTime(timezone=True), nullable=True),
        sa.Column('check_out', sa.DateTime(timezone=True), nullable=True),
        sa.Column('duration_minutes', sa.Integer(), nullable=True),
        sa.Column('method', sa.String(20), nullable=True),
        sa.Column('location', postgresql.JSONB(), nullable=True),
        sa.Column('status', sa.String(20), server_default='present'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('user_id', 'date', name='uq_attendance_user_date'),
    )

    # Indexes for common query patterns
    op.create_index('ix_attendance_org_date', 'attendance_records', ['org_id', 'date'])
    op.create_index('ix_attendance_user_date', 'attendance_records', ['user_id', 'date'])
    op.create_index('ix_users_org_role', 'users', ['org_id', 'role'])


def downgrade() -> None:
    op.drop_table('attendance_records')
    op.drop_table('face_data')
    op.drop_table('users')
    op.drop_table('guest_accounts')
    op.drop_table('organizations')
