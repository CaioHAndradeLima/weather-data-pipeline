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
  --conn-host "http://host.docker.internal:8000/api/public/v1"

echo "Airflow Airbyte connection created successfully!"
