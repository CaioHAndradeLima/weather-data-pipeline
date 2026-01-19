#!/bin/bash
set -e

# Starting postgres and CDC connectors
docker compose \
  --env-file ../../.env \
  -f postgres/docker-compose.yml \
  -f postgres/kafka/docker-compose.yml \
  -f airflow/docker-compose.yml \
  up -d > containers_init_log.txt

# Waiting for Kafka Connect to be ready

until curl -s http://localhost:8083/ > /dev/null; do
  echo "Waiting for Kafka Connect..."
  sleep 5
done

# Kafka Connect is ready. Registering Debezium connector
if curl -s http://localhost:8083/connectors/retail-postgres-connector | grep -q '"name"'; then
  echo "Debezium connector has been found"
else
  curl -X POST http://localhost:8083/connectors \
    -H "Content-Type: application/json" \
    -d @postgres/kafka/connectors/debezium-postgres.json
fi

# Create airflow user
echo "Airflow user: admin password: admin"
#chmod +x airflow/util/create_user.sh
#./airflow/util/create_user.sh