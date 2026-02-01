#!/bin/bash
set -e

# permission to execute airbyte scripts
chmod +x ./airbyte/create_connections.sh
chmod +x ./airbyte/setup_postgres_source.sh
chmod +x ./airbyte/setup_snowflake_destination.sh
chmod +x ./airbyte/generate_tables_json.sh
chmod +x ./airbyte/setup_credentials.sh
chmod +x ./airbyte/start_airbyte.sh
chmod +x ./airbyte/login.sh

./airbyte/start_airbyte.sh

# Starting postgres and CDC connectors
docker compose \
  --env-file ../../.env \
  -f postgres/docker-compose.yml \
  up -d

# airbyte set up
cd airbyte;

./setup_credentials.sh
./setup_postgres_source.sh
./setup_snowflake_destination.sh
./generate_tables_json.sh
./create_connections.sh



cd ..;
cd airflow;
docker compose \
  --env-file ../../../.env \
  -f docker-compose.yml \
  up -d
cd ..;

# Logging airflow user
echo "Airflow user: admin password: admin"

