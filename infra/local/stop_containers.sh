#!/bin/bash

abctl local uninstall
rm -rf ~/.airbyte/abctl/data

docker compose \
  -f postgres/docker-compose.yml \
  down -v

docker compose \
  -f airflow/docker-compose.yml \
  down -v
