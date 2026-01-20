import logging

from src.ingestion.kafka.consumer import read_from_kafka
from src.snowflake.writer import write_to_snowflake

logger = logging.getLogger(__name__)


def consume_and_write_orders():
    consumer, events, messages = read_from_kafka(
        topic="retail.retail.orders",
        group_id="airflow-bronze-orders",
        max_messages=10000,
    )

    logger.info("Fetched %d events from Kafka", len(events))

    if not events:
        consumer.close()
        return

    # Writes to Snowflake and commits offsets ONLY if success
    write_to_snowflake(
        consumer=consumer,
        events=events,
        messages=messages,
    )
    logger.info("Successfully wrote events to Snowflake and committed offsets")
