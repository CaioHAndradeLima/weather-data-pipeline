#!/bin/bash
set -e

docker exec -i local-postgres psql -U retail_user -d retail_prod <<'SQL'
INSERT INTO retail.orders
VALUES ('dddddddd-dddd-dddd-dddd-ddddddddddee', '11111111-1111-1111-1111-111111111111', 'CREATED', 129.80, 'USD', now(),
        now());
SQL
