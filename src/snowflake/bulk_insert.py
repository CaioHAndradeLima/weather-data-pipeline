import base64
import json
import logging
import tempfile
import uuid
from datetime import datetime, timezone
from decimal import Decimal

from src.snowflake.connection import get_snowflake_connection

logger = logging.getLogger(__name__)


def snowflake_bulk_insert_order_events(events: list) -> None:
    if not events:
        return

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        for event in events:
            payload = event["payload"]
            after = payload.get("after") or {}

            record = {
                "EVENT_ID": str(uuid.uuid4()),
                "EVENT_TYPE": payload["op"],
                "EVENT_VERSION": 1,
                "ORDER_ID": after.get("order_id"),
                "CUSTOMER_ID": after.get("customer_id"),
                "ORDER_STATUS": after.get("order_status"),
                "ORDER_TOTAL": str(decode_decimal(after.get("order_total"))),
                "CURRENCY": after.get("currency"),
                "EVENT_TIMESTAMP": datetime.fromtimestamp(
                    payload["ts_ms"] / 1000, tz=timezone.utc
                ).isoformat(),
                "PRODUCED_AT": after.get("updated_at"),
                "INGESTED_AT": datetime.now(tz=timezone.utc).isoformat(),
                "SOURCE_SYSTEM": "postgres",
                "KAFKA_TOPIC": event.get("topic"),
                "KAFKA_PARTITION": event.get("partition"),
                "KAFKA_OFFSET": event.get("offset"),
            }

            f.write(json.dumps(record) + "\n")

        file_path = f.name

    conn = get_snowflake_connection(
        database="RETAIL_ANALYTICS",
        schema="BRONZE",
        warehouse="RETAIL_WH"
    )

    cursor = conn.cursor()

    try:
        # Upload file to table stage
        cursor.execute(
            f"PUT file://{file_path} @%ORDER_EVENTS AUTO_COMPRESS=TRUE"
        )

        # Bulk load into table
        cursor.execute(
            """
            COPY INTO ORDER_EVENTS
            FROM @%ORDER_EVENTS
            FILE_FORMAT = (TYPE = JSON)
            MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
            """
        )
    except Exception:
        logger.exception("Snowflake ingestion failed")
        raise

    finally:
        cursor.close()
        conn.close()


def decode_decimal(value: str, scale: int = 2):
    if value is None:
        return None

    raw = base64.b64decode(value)
    unscaled = int.from_bytes(raw, byteorder="big", signed=True)
    return Decimal(unscaled).scaleb(-scale)
