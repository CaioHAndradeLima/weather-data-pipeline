#!/bin/bash

docker compose \
  -f postgres/docker-compose.yml \
  -f postgres/kafka/docker-compose.yml \
  -f airflow/docker-compose.yml \
  down -v
