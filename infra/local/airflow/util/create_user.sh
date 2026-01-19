#!/bin/bash
set -e

echo "Initializing Airflow metadata database"
echo "Creating admin user (admin / admin)"
echo ""

docker compose exec airflow-scheduler bash -c "airflow db migrate &&
      airflow users list |
      grep admin ||
      airflow users create --username admin --password admin --firstname Admin --lastname User --role Admin --email admin@example.com;"

