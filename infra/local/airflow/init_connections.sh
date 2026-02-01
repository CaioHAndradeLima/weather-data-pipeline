#!/bin/bash
set -e

echo "Creating Airflow connections..."

airflow connections delete airbyte_http || true
airflow connections add airbyte_http \
  --conn-type http \
  --conn-host "http://host.docker.internal:8000"

echo " Updating Airflow connection..."

airflow connections delete airbyte_default || true

airflow connections add airbyte_default \
  --conn-type airbyte \
  --conn-host "http://host.docker.internal:8000/api/public/v1" \
  --conn-schema "v1/applications/token" \
  --conn-login $AIRBYTE_CLIENT_ID \
  --conn-password $AIRBYTE_CLIENT_SECRET \

echo "Airflow Airbyte connection created successfully!"

airflow pools set airbyte_sequential 1 "Run Airbyte syncs one at a time"
