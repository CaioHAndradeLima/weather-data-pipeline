#!/bin/bash

abctl local uninstall
rm -rf ~/.airbyte/abctl/data

docker compose \
  -f postgres/docker-compose.yml \
  -f airflow/docker-compose.yml \
  down -v
