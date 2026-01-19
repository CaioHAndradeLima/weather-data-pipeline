resource "snowflake_table" "bronze_order_events" {
  database = snowflake_database.retail_analytics.name
  schema   = snowflake_schema.bronze.name
  name     = "ORDER_EVENTS"

  column {
    name     = "EVENT_ID"
    type     = "STRING"
    nullable = false
  }

  column {
    name     = "EVENT_TYPE"
    type     = "STRING"
    nullable = false
  }

  column {
    name = "EVENT_VERSION"
    type = "INTEGER"
  }

  column {
    name     = "ORDER_ID"
    type     = "STRING"
    nullable = true
  }

  column {
    name = "CUSTOMER_ID"
    type = "STRING"
  }

  column {
    name = "ORDER_STATUS"
    type = "STRING"
  }

  column {
    name = "ORDER_TOTAL"
    type = "NUMBER(10,2)"
  }

  column {
    name = "CURRENCY"
    type = "STRING"
  }

  column {
    name     = "EVENT_TIMESTAMP"
    type     = "TIMESTAMP_TZ"
    nullable = false
  }

  column {
    name = "PRODUCED_AT"
    type = "TIMESTAMP_TZ"
  }

  column {
    name = "INGESTED_AT"
    type = "TIMESTAMP_TZ"
  }

  column {
    name = "SOURCE_SYSTEM"
    type = "STRING"
  }

  column {
    name = "KAFKA_TOPIC"
    type = "STRING"
  }

  column {
    name = "KAFKA_PARTITION"
    type = "INTEGER"
  }

  column {
    name = "KAFKA_OFFSET"
    type = "INTEGER"
  }
}

resource "snowflake_table" "bronze_payment_events" {
  database = snowflake_database.retail_analytics.name
  schema   = snowflake_schema.bronze.name
  name     = "PAYMENT_EVENTS"

  column {
    name     = "EVENT_ID"
    type     = "STRING"
    nullable = false
  }
  column {
    name     = "EVENT_TYPE"
    type     = "STRING"
    nullable = false
  }
  column {
    name = "EVENT_VERSION"
    type = "INTEGER"
  }

  column {
    name     = "PAYMENT_ID"
    type     = "STRING"
    nullable = false
  }
  column {
    name     = "ORDER_ID"
    type     = "STRING"
    nullable = false
  }

  column {
    name = "PAYMENT_STATUS"
    type = "STRING"
  }
  column {
    name = "PAYMENT_METHOD"
    type = "STRING"
  }
  column {
    name = "AMOUNT"
    type = "NUMBER(10,2)"
  }
  column {
    name = "CURRENCY"
    type = "STRING"
  }

  column {
    name     = "EVENT_TIMESTAMP"
    type     = "TIMESTAMP_TZ"
    nullable = false
  }
  column {
    name = "PRODUCED_AT"
    type = "TIMESTAMP_TZ"
  }
  column {
    name = "INGESTED_AT"
    type = "TIMESTAMP_TZ"
  }

  column {
    name = "SOURCE_SYSTEM"
    type = "STRING"
  }
  column {
    name = "KAFKA_TOPIC"
    type = "STRING"
  }
  column {
    name = "KAFKA_PARTITION"
    type = "INTEGER"
  }
  column {
    name = "KAFKA_OFFSET"
    type = "INTEGER"
  }
}

resource "snowflake_table" "bronze_shipment_events" {
  database = snowflake_database.retail_analytics.name
  schema   = snowflake_schema.bronze.name
  name     = "SHIPMENT_EVENTS"


  column {
    name     = "EVENT_ID"
    type     = "STRING"
    nullable = false
  }
  column {
    name     = "EVENT_TYPE"
    type     = "STRING"
    nullable = false
  }
  column {
    name = "EVENT_VERSION"
    type = "INTEGER"
  }

  column {
    name     = "SHIPMENT_ID"
    type     = "STRING"
    nullable = false
  }
  column {
    name     = "ORDER_ID"
    type     = "STRING"
    nullable = false
  }
  column {
    name = "SHIPMENT_STATUS"
    type = "STRING"
  }
  column {
    name = "CARRIER"
    type = "STRING"
  }

  column {
    name     = "EVENT_TIMESTAMP"
    type     = "TIMESTAMP_TZ"
    nullable = false
  }
  column {
    name = "PRODUCED_AT"
    type = "TIMESTAMP_TZ"
  }
  column {
    name = "INGESTED_AT"
    type = "TIMESTAMP_TZ"
  }
  column {
    name = "SOURCE_SYSTEM"
    type = "STRING"
  }
  column {
    name = "KAFKA_TOPIC"
    type = "STRING"
  }
  column {
    name = "KAFKA_PARTITION"
    type = "INTEGER"
  }
  column {
    name = "KAFKA_OFFSET"
    type = "INTEGER"
  }
}
