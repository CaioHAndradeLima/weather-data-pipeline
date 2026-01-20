import uuid
from datetime import datetime, timezone

from src.snowflake.loader import snowflake_bulk_insert


def map_and_write_payment_events(rows: list) -> None:
    records = []

    for row in rows:
        records.append(
            {
                "EVENT_ID": str(uuid.uuid4()),
                "EVENT_TYPE": "PAYMENT_UPSERT",
                "EVENT_VERSION": 1,
                "PAYMENT_ID": str(row["payment_id"]),
                "ORDER_ID": str(row["order_id"]),
                "PAYMENT_STATUS": row["payment_status"],
                "PAYMENT_METHOD": row["payment_method"],
                "AMOUNT": str(row["amount"]),
                "CURRENCY": row["currency"],
                "EVENT_TIMESTAMP": row["updated_at"].isoformat(),
                "PRODUCED_AT": row["updated_at"].isoformat(),
                "INGESTED_AT": datetime.now(tz=timezone.utc).isoformat(),
                "SOURCE_SYSTEM": "postgres",
                "KAFKA_TOPIC": None,
                "KAFKA_PARTITION": None,
                "KAFKA_OFFSET": None,
            }
        )

    snowflake_bulk_insert(
        table_name="PAYMENT_EVENTS",
        records=records,
        database="RETAIL_ANALYTICS",
        schema="BRONZE",
        warehouse="RETAIL_WH",
    )
