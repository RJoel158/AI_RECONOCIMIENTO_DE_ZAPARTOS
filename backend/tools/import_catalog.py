from __future__ import annotations

import argparse
import csv
from pathlib import Path

from app.core.database import SessionLocal
from app.models.product import Product
from app.models.stock import Stock


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import products and stock from CSV")
    parser.add_argument(
        "--products",
        default=None,
        help="Path to products CSV (default: data/products.csv)",
    )
    parser.add_argument(
        "--stock",
        default=None,
        help="Path to stock CSV (default: data/stock.csv)",
    )
    return parser.parse_args()


def load_products(db, csv_path: Path) -> dict[str, int]:
    created = 0
    updated = 0

    with csv_path.open("r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            sku = (row.get("sku") or "").strip()
            if not sku:
                continue

            product = db.query(Product).filter(Product.sku == sku).first()
            payload = {
                "sku": sku,
                "brand": (row.get("brand") or "").strip(),
                "model_name": (row.get("model_name") or "").strip(),
                "type": (row.get("type") or "").strip(),
                "color_primary": (row.get("color_primary") or "").strip(),
                "color_secondary": (row.get("color_secondary") or "").strip() or None,
                "material": (row.get("material") or "").strip() or None,
                "gender": (row.get("gender") or "").strip() or None,
            }

            if product:
                for key, value in payload.items():
                    setattr(product, key, value)
                updated += 1
            else:
                db.add(Product(**payload))
                created += 1

    db.commit()
    return {"created": created, "updated": updated}


def load_stock(db, csv_path: Path) -> dict[str, int]:
    created = 0
    updated = 0
    skipped = 0

    with csv_path.open("r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            sku = (row.get("sku") or "").strip()
            size = (row.get("size") or "").strip()
            quantity_raw = (row.get("quantity") or "0").strip()

            if not sku or not size:
                skipped += 1
                continue

            try:
                quantity = int(quantity_raw)
            except ValueError:
                skipped += 1
                continue

            product = db.query(Product).filter(Product.sku == sku).first()
            if not product:
                skipped += 1
                continue

            stock_item = (
                db.query(Stock)
                .filter(Stock.product_id == product.id, Stock.size == size)
                .first()
            )
            if stock_item:
                stock_item.quantity = quantity
                updated += 1
            else:
                db.add(Stock(product_id=product.id, size=size, quantity=quantity))
                created += 1

    db.commit()
    return {"created": created, "updated": updated, "skipped": skipped}


def main() -> None:
    args = parse_args()
    base_dir = Path(__file__).resolve().parents[1]
    data_dir = base_dir.parent / "data"

    products_path = Path(args.products) if args.products else data_dir / "products.csv"
    stock_path = Path(args.stock) if args.stock else data_dir / "stock.csv"

    if not products_path.exists():
        raise FileNotFoundError(f"Products CSV not found: {products_path}")
    if not stock_path.exists():
        raise FileNotFoundError(f"Stock CSV not found: {stock_path}")

    db = SessionLocal()
    try:
        product_stats = load_products(db, products_path)
        stock_stats = load_stock(db, stock_path)
    finally:
        db.close()

    print("Products:", product_stats)
    print("Stock:", stock_stats)


if __name__ == "__main__":
    main()
