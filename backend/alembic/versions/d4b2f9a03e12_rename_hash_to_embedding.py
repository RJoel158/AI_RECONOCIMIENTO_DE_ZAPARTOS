"""rename image_hash to image_embedding

Revision ID: d4b2f9a03e12
Revises: c3a1f8e92d01
Create Date: 2026-05-07
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

# revision identifiers
revision: str = 'd4b2f9a03e12'
down_revision: Union[str, None] = 'c3a1f8e92d01'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Check which columns exist and handle all cases
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('products')]

    # Add image_data if missing
    if 'image_data' not in columns:
        op.add_column('products', sa.Column('image_data', sa.Text(), nullable=True))

    # Handle image_hash → image_embedding rename
    if 'image_hash' in columns and 'image_embedding' not in columns:
        op.alter_column('products', 'image_hash', new_column_name='image_embedding', type_=sa.Text())
    elif 'image_hash' not in columns and 'image_embedding' not in columns:
        op.add_column('products', sa.Column('image_embedding', sa.Text(), nullable=True))
    # If image_embedding already exists, do nothing


def downgrade() -> None:
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('products')]

    if 'image_embedding' in columns:
        op.alter_column('products', 'image_embedding', new_column_name='image_hash', type_=sa.String(16))
