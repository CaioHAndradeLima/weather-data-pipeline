#!/bin/bash
echo "Waiting for Kafka Connect..."
sleep 15

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @/connectors/debezium-postgres.json
