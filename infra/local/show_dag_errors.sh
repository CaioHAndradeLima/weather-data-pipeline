#!/bin/bash

docker compose exec airflow-scheduler bash /opt/airflow/validation/validate_dags.sh