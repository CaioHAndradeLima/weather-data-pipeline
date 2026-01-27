DROP PUBLICATION IF EXISTS airbyte_publication;

CREATE PUBLICATION airbyte_publication
FOR TABLE retail.orders;

SELECT pg_create_logical_replication_slot(
  'airbyte_slot',
  'pgoutput'
);
