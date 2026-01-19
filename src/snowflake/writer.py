from src.snowflake.bulk_insert import snowflake_bulk_insert_order_events


def write_to_snowflake(consumer, events, messages):
    if not events:
        return

    # Write to Snowflake
    snowflake_bulk_insert_order_events(events)

    # Commit Kafka offsets ONLY if Snowflake succeeded
    consumer.commit(asynchronous=False)

    # Close consumer
    consumer.close()
