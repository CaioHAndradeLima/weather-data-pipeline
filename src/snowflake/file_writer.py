from src.snowflake.loader import snowflake_bulk_insert


def write_to_snowflake(consumer, events, messages):
    if not events:
        return

    # Write to Snowflake
    snowflake_bulk_insert(events)

    # Commit Kafka offsets ONLY if Snowflake succeeded
    consumer.commit(asynchronous=False)

    # Close consumer
    consumer.close()
