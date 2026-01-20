from datetime import datetime, timezone

from src.snowflake.loader import snowflake_bulk_insert

def write_customers_snapshot(rows: list) -> None:
    snapshot_date = datetime.now(tz=timezone.utc).date()

    records = [
        {
            "CUSTOMER_ID": str(r["customer_id"]),
            "NAME": r["full_name"],
            "EMAIL": r["email"],
            "COUNTRY": r["country"],
            "CREATED_AT": r["created_at"].isoformat(),
            "SNAPSHOT_DATE": snapshot_date.isoformat(),
            "INGESTED_AT": datetime.now(tz=timezone.utc).isoformat(),
        }
        for r in rows
    ]

    snowflake_bulk_insert(
        table_name="CUSTOMERS_SNAPSHOT",
        records=records,
        database="RETAIL_ANALYTICS",
        schema="BRONZE",
        warehouse="RETAIL_WH",
    )


def write_products_snapshot(rows: list) -> None:
    snapshot_date = datetime.now(tz=timezone.utc).date()

    records = [
        {
            "PRODUCT_ID": str(r["product_id"]),
            "PRODUCT_NAME": r["product_name"],
            "CATEGORY": r["category"],
            "PRICE": str(r["price"]),
            "ACTIVE": r["active"],
            "SNAPSHOT_DATE": snapshot_date.isoformat(),
            "INGESTED_AT": datetime.now(tz=timezone.utc).isoformat(),
        }
        for r in rows
    ]

    snowflake_bulk_insert(
        table_name="PRODUCTS_SNAPSHOT",
        records=records,
        database="RETAIL_ANALYTICS",
        schema="BRONZE",
        warehouse="RETAIL_WH",
    )
