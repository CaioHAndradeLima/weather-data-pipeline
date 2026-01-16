# retail-data-pipeline

``````
            ┌──────────────┐
            │ Batch Source │
            │ (JSON / API) │
            └──────┬───────┘
                   |
            Python Extract
                   |
                   v
┌──────────────┐   Airflow   ┌──────────────┐
│ Kafka        │────────────▶│ Snowflake    │
│ (Events)     │             │ Bronze       │
└──────┬───────┘             │ (Raw Events) │
       |                     └──────┬───────┘
   Kafka Consumer                    |
                                     v
                               dbt (Silver)
                                     |
                                     v
                               dbt (Gold)
                                     |
                                     v
                                  Power BI
``````


Questions to answer

<h3>Core Business Questions (what the business wants)</h3>

* How many orders are created per day?
* How much revenue are we generating?
* What is the order conversion rate?
* Which products generate the most revenue?
* What percentage of orders are canceled or refunded?
* How long does it take for an order to move from created → shipped → delivered?

<h4>These questions naturally justify</h4>

* Streaming data
* Incremental models
* Gold BI tables


<h3>Entities (stable reference data)</h3>

These change slowly → batch ingestion

<b>Customers</b>
customer_id
name,
email,
country,
created_at
<br><b>Products</b>
product_id,
product_name,
category,
price,
active


Kafka events:

order_created
order_updated
order_canceled

``` json
{
  "event_id": "evt_001",
  "event_type": "order_created",
  "event_version": 1,

  "order_id": "ord_123",
  "customer_id": "cust_45",

  "order_total": 129.99,
  "currency": "USD",

  "order_status": "CREATED",

  "event_timestamp": "2026-01-15T12:30:00Z",
  "produced_at": "2026-01-15T12:30:02Z",

  "source_system": "checkout_service"
}
```

Kafka payments:

payment_authorized
payment_captured
payment_failed
payment_refunded

``` json
{
  "event_id": "evt_101",
  "event_type": "payment_captured",
  "event_version": 1,

  "payment_id": "pay_987",
  "order_id": "ord_123",

  "amount": 129.99,
  "currency": "USD",
  "payment_method": "credit_card",

  "payment_status": "CAPTURED",

  "event_timestamp": "2026-01-15T12:31:10Z",
  "produced_at": "2026-01-15T12:31:12Z",

  "source_system": "payment_service"
}
```

Kafka Shipment:
shipment_created
shipment_dispatched
shipment_delivered
shipment_failed

``` json
{
  "event_id": "evt_201",
  "event_type": "shipment_dispatched",
  "event_version": 1,

  "shipment_id": "shp_555",
  "order_id": "ord_123",
  "carrier": "DHL",

  "shipment_status": "DISPATCHED",

  "event_timestamp": "2026-01-15T18:00:00Z",
  "produced_at": "2026-01-15T18:00:03Z",

  "source_system": "logistics_service"
}
``` 

Structure

``` yml
Terraform
   |
   v
Snowflake Provider
   |
   v
Snowflake Account

------ Data Pipeline Flow -------

Terraform
   ↓
Snowflake (schemas, tables)
   ↓
Python Ingestion
   ↓
Bronze tables
   ↓
dbt (Silver → Gold)
   ↓
Power BI

``` 

| Layer                          | Tool             |
| ------------------------------ | ---------------- |
| Infra (schemas, tables, roles) | Terraform        |
| Ingestion (raw data)           | Python + Airflow |
| Transformations                | dbt              |
| Analytics                      | Power BI         |
| Storage / Compute              | Snowflake        |


``` yml
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
│
├── modules/
│   ├── snowflake_database/
│   │   └── main.tf
│   │
│   ├── snowflake_schema/
│   │   └── main.tf
│   │
│   ├── snowflake_warehouse/
│   │   └── main.tf
│   │
│   ├── bronze_tables/
│   │   └── main.tf
│   │
│   └── roles_and_grants/
│       └── main.tf
│
├── provider.tf
└── versions.tf
```

ingestion
``` yml
ingestion/
├── kafka/
│   ├── consumer.py          # Kafka consumer
│   ├── schemas.py           # Event schemas
│   └── config.py
│
├── batch/
│   ├── load_customers.py    # JSON snapshot ingestion
│   ├── load_products.py
│   └── utils.py
│
├── snowflake/
│   ├── connection.py
│   └── writer.py            # Insert logic
│
├── requirements.txt
└── README.md
```
Airflow
``` yml
airflow/
├── dags/
│   ├── retail_kafka_ingestion_dag.py
│   ├── retail_batch_ingestion_dag.py
│   ├── retail_dbt_dag.py
│   └── utils.py
│
├── plugins/
│
├── requirements.txt
└── README.md
```

DBT
``` yml
dbt/
├── dbt_project.yml
├── profiles.yml
│
├── models/
│   ├── silver/
│   │   ├── orders.sql
│   │   ├── payments.sql
│   │   ├── shipments.sql
│   │   └── schema.yml
│   │
│   └── gold/
│       ├── daily_revenue.sql
│       ├── orders_by_status.sql
│       ├── top_products.sql
│       └── schema.yml
│
├── tests/
│   ├── generic_tests.yml
│
├── macros/
│
└── README.md
```

Local Development infra
``` yml
docker/
├── airflow/
│   └── Dockerfile
│
├── kafka/
│   └── docker-compose.kafka.yml
│
└── dbt/
    └── Dockerfile
```

How to run this project locally:

you should have an account in snowflake

install brew
install snowflake cli through:
brew install --cask snowflake-snowsql

run create snowflake user to terraform

and then run terraform apply



install local python dependencies:

pip install --upgrade pip
pip install -r requirements.txt

``` yml
         ┌────────────┐
         │  Postgres  │
         └─────┬──────┘
               │
        Airflow (batch DAG)
               │
         Snowflake BRONZE
               │
     ┌─────────┴─────────┐
     │                   │
Python Event Gen     dbt Silver
(Streaming sim)          │
     │               Snowflake GOLD
     └──────────────▶ Power BI
```
