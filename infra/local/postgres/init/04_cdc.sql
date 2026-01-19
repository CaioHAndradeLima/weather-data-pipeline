-- Create publication for all tables
DROP PUBLICATION IF EXISTS retail_cdc_pub;

CREATE PUBLICATION retail_cdc_pub
FOR TABLE retail.orders;
