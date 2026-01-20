import uuid
from datetime import datetime, timezone

from src.snowflake.loader import snowflake_bulk_insert


def map_and_write_shipment_events(rows: list) -> None:
    records = []

    for row in rows:
        records.append(
            {
                "EVENT_ID": str(uuid.uuid4()),
                "EVENT_TYPE": "SHIPMENT_UPSERT",
                "EVENT_VERSION": 1,
                "SHIPMENT_ID": str(row["shipment_id"]),
                "ORDER_ID": str(row["order_id"]),
                "SHIPMENT_STATUS": row["shipment_status"],
                "CARRIER": row["carrier"],
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
        table_name="SHIPMENT_EVENTS",
        records=records,
        database="RETAIL_ANALYTICS",
        schema="BRONZE",
        warehouse="RETAIL_WH",
    )
