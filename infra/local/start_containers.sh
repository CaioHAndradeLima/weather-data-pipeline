#!/bin/bash
set -e

chmod +x ./airbyte/create_connection.sh
chmod +x ./airbyte/create_postgres_source.sh
chmod +x ./airbyte/create_snowflake_connection.sh
chmod +x ./airbyte/generate_tables_json.sh
chmod +x ./airbyte/start_airbyte.sh

./airbyte/start_airbyte.sh

# Starting postgres and CDC connectors
docker compose \
  --env-file ../../.env \
  -f postgres/docker-compose.yml \
  -f airflow/docker-compose.yml \
  up -d > containers_init_log.txt

# Create airflow user
echo "Airflow user: admin password: admin"

# airbyte set up
cd airbyte;

./create_postgres_source.sh
./create_snowflake_connection.sh
./generate_tables_json.sh
./create_connection.sh

cd ..;

