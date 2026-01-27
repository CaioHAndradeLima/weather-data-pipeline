#!/bin/bash
set -e

echo "Creating Airflow connections..."

# -------------------------
# Postgres Retail
# -------------------------
airflow connections delete postgres_retail || true

airflow connections add postgres_retail \
  --conn-type postgres \
  --conn-host "$RETAIL_PG_HOST" \
  --conn-schema "$RETAIL_PG_DB" \
  --conn-login "$RETAIL_PG_USER" \
  --conn-password "$RETAIL_PG_PASSWORD" \
  --conn-port "$RETAIL_PG_PORT"

# -------------------------
# Snowflake Retail
# -------------------------
airflow connections delete snowflake_retail || true

airflow connections add snowflake_retail \
  --conn-type snowflake \
  --conn-login "$SNOWFLAKE_USER" \
  --conn-password "$SNOWFLAKE_PASSWORD" \
  --conn-extra "{
    \"account\": \"$SNOWFLAKE_ACCOUNT\",
    \"warehouse\": \"$SNOWFLAKE_WAREHOUSE\",
    \"database\": \"$SNOWFLAKE_DATABASE\",
    \"schema\": \"$SNOWFLAKE_SCHEMA\",
    \"role\": \"$SNOWFLAKE_ROLE\"
  }"



echo "Connecting airbyte"

airflow connections delete airbyte_conn || true

airflow connections add airbyte_conn \
  --conn-type http \
  --conn-host "http://host.docker.internal:8001"

echo "Airflow connections created successfully."
