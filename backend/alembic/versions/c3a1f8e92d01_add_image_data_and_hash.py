"""add image_data and image_hash columns

Revision ID: c3a1f8e92d01
Revises: 2bc4531c97bb
Create Date: 2026-05-07
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = 'c3a1f8e92d01'
down_revision: Union[str, None] = '2bc4531c97bb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('products', sa.Column('image_data', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('image_hash', sa.String(length=16), nullable=True))


def downgrade() -> None:
    op.drop_column('products', 'image_hash')
    op.drop_column('products', 'image_data')
