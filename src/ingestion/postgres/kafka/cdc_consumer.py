import json

from confluent_kafka import Consumer


def read_from_kafka(
    topic: str,
    bootstrap_servers="kafka:29092",
    group_id="airflow-bronze-consumer",
    max_messages=10000,
    max_empty_polls=5,
):
    consumer = Consumer(
        {
            "bootstrap.servers": bootstrap_servers,
            "group.id": group_id,
            "auto.offset.reset": "earliest",
            "enable.auto.commit": False,
        }
    )

    consumer.subscribe([topic])

    events = []
    messages = []
    empty_polls = 0

    while len(events) < max_messages and empty_polls < max_empty_polls:
        msg = consumer.poll(timeout=1.0)

        if msg is None:
            empty_polls += 1
            continue

        empty_polls = 0

        if msg.error():
            raise Exception(msg.error())

        event = json.loads(msg.value().decode("utf-8"))

        events.append(
            {
                "payload": event.get("payload"),
                "schema": event.get("schema"),
                "topic": msg.topic(),
                "partition": msg.partition(),
                "offset": msg.offset(),
                "timestamp": msg.timestamp()[1],
            }
        )

        messages.append(msg)

    return consumer, events, messages
