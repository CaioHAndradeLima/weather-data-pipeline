# retail-data-pipeline

[![Retail Data Pipeline](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml)

<h1> Data Pipeline Architecture </h1>

This project simulate a retail pipeline containing a RDS AWS database as production and the following questions to answer:

* How many orders are created per day?
* How much revenue are we generating?
* What is the order conversion rate?
* Which products generate the most revenue?
* What percentage of orders are canceled or refunded?
* How long does it take for an order to move from created → shipped → delivered?

in addition, we have CDC enabled for order table in RDS, all other table should be consumed using batch approach.


``````
                     ┌──────────────────────┐
                     │   Source Systems     │
                     │ Postgree OLTP / CDC  │
                     └──────────┬───────────┘
                                |
          ┌─────────────────────┴─────────────────────┐
          │                                           │
   (Batch / ELT)                               (CDC / Events)
          │                                           │
          │                                     Debezium (CDC)
          │                                           │
          v                                           v
┌─────────────────────────┐               ┌────────────────────────┐
│ Snowflake               │               │ Kafka                  │
│ BRONZE_BATCH            │               │ CDC Topics             │
│ Raw API / Snapshot Data │               │ (c / u / d events)     │
└──────────┬──────────────┘               └──────────┬─────────────┘
           │                                         │
          dbt                                  Python Consumers
           │                                (Micro-batch logic)
           v                               (Airflow – every 5 min)
┌────────────────────────┐                           │
│ Snowflake              │                           v
│ SILVER_BATCH           │                ┌────────────────────────┐
│ Clean / Normalized     │                │ Snowflake              │
└──────────┬─────────────┘                │ BRONZE_CDC             │
           │                              │ Raw Change Events      │
          dbt                             └──────────┬─────────────┘
           │                                         |
           v                                        dbt
┌─────────────────────────┐                          |
│ Snowflake               │                          v
│ GOLD                    │◄─────────────────────────+
│ Business Metrics / Marts│    (Merge / Align)
└──────────┬──────────────┘
           |
       BI / Analytics
``````

<h1> Snowflake Lake House </h1>

we're using Snowflake to save data using medallion architecture (bronze,silver,gold).

| Layer                          | Tool                         |
| ------------------------------ |------------------------------|
| Infra (schemas, tables, roles) | Bash + Terraform + Snowflake |
| Ingestion (raw data)           | Python + Airflow             |
| Transformations                | dbt                          |
| Analytics                      | Power BI                     |
| Storage / Compute              | Snowflake                    |

You can create all Snowflake structure only using the ./setup.sh file in the project.


<h1> Infrastructure overview: Infra as a code </h1>

This project uses a hybrid local + cloud infrastructure to simulate and run a real-world data platform with CDC, Kafka, Airflow, and a Medallion architecture on Snowflake.

``` yml
infra/
├── local/        # Local development & simulation environment
├── snowflake/    # Analytics platform (Medallion architecture)
└── remote/       # Cloud infrastructure (AWS)
```

The local environment is used to simulate a production-like data platform entirely on Docker.
It includes:
OLTP database with CDC enabled
Kafka + Debezium
Airflow for orchestration
Sample data generation

``` yml
infra/local/
├── airflow/
│   ├── util/                       # util scripts
│   ├── validation/                 # validation dag files script
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── init_connections.sh         # add snowflake connection whenever it launch
│
├── postgres/
│   └── init/
│       ├── 01_wal_level_setup.sql  # set wal_level = logical
│       ├── 02_init_retail_oltp.sql # create tables
│       ├── 03_data.sql             # insert mock data into tables
│       ├── 04_cdc.sql              # enable cdc
│       └── 05_debezium_user.sql    # set up Debezium role for CDC Kafka events
│
├── kafka/
│   ├── connectors/
│   │   ├── debezium-postgres.json  # Debezium set up
│   │   └── register.sh             # Script to register .json into Debezium
│   └── docker-compose.yml
│
├── start_containers.sh             # start all local infra
├── stop_containers.sh              # stop all local infra
└── insert_new_order.sh             # use to test CDC
```

<h1> Snowflake Analytics platform (Medallion) </h1>
This folder defines the Snowflake environment that supports the Bronze / Silver / Gold layers.
Responsibilities
Create databases and schemas
Define Bronze tables (events & snapshots)
Configure warehouses
Manage roles, grants, and permissions
Prepare the platform for dbt transformations

``` yml
infra/snowflake/
├── setup/
│   ├── generate_terraform_user.sh  # generate Snowflake Terraform user
│   ├── install_local_cli.sh        # Install Snowflake CLI locally
│   └── roles.sql                   # Snowflake SQL Query to create the Terraform Role
│
├── bronze_tables_events.tf
├── bronze_tables_snapshots.tf
├── warehouse.tf
├── grants.tf
├── main.tf
├── provider.tf
├── variables.tf
└── versions.tf
```

<h1> How to run this project locally: </h1>

The project was made to run it only executing a setup.sh script. 
The script will be responsible for guarantee your current environment is working as expected and do not require complex set up.

you just need create a Snowflake account or use your current one.

Requirements: 
* Mac OS Environment
* Docker installed and running 
* Brew installed 
* Snowflake CLI installed (brew install --cask snowflake-snowsql)
* Python installed
* PIP installed



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


| Feature            | Current Python / Airflow Approach                         | High-Standard Approach (Kafka Connect)              |
|--------------------|------------------------------------------------------------|-----------------------------------------------------|
| Duplicate Handling | Depends on Kafka commits (risk of duplicates)              | Exactly-once delivery via Snowflake Pipe             |
| Complexity         | Low (custom Python logic)                                  | Medium (requires Kafka Connect cluster)              |
| Latency            | Batch-based (data processed when Airflow runs)             | Near real-time (seconds)                             |
| CDC Handling       | Hard to handle Debezium `DELETE` and update events          | Native support for CDC schemas (Debezium-compatible) |



dbt orchestration approachs:

| Aspect                    | **Approach A — CLI-based dbt orchestration** | **Approach B — dbt Cosmos (Task-per-model)** |
| ------------------------- | -------------------------------------------- | -------------------------------------------- |
| Orchestration unit        | dbt commands (`dbt run`, `dbt test`)         | Individual dbt models and tests              |
| Airflow complexity        | ⭐ Low                                        | ⭐⭐⭐ High                                     |
| Setup effort              | Minimal                                      | Moderate to high                             |
| Learning curve            | Easy                                         | Steep                                        |
| dbt dependency handling   | Fully handled by dbt                         | Reflected in Airflow DAG                     |
| Airflow DAG size          | Small and clean                              | Large and dynamic                            |
| Observability in Airflow  | Limited (command-level)                      | Excellent (model-level)                      |
| Failure granularity       | Pipeline-level failure                       | Model-level failure                          |
| Retry strategy            | Retry full dbt run                           | Retry failed models only                     |
| Debugging                 | Simple (CLI logs)                            | Requires understanding Cosmos internals      |
| Local development         | Very easy                                    | More complex                                 |
| CI/CD friendliness        | Excellent                                    | Good but heavier                             |
| Scalability               | High                                         | Very high                                    |
| Operational overhead      | Low                                          | Medium to high                               |
| Best for                  | Startups, mid-size teams, portfolio projects | Mature data platforms, analytics-heavy orgs  |
| Industry adoption         | ⭐⭐⭐⭐⭐ (most common)                          | ⭐⭐⭐ (growing, but niche)                     |
| Recommended as first step | ✅ Yes                                        | ❌ No                                         |
| Migration path            | Easy → Cosmos later                          | Hard to downgrade                            |


production environment:

``` yml
┌────────────┐
│   RDS      │
│ Postgres   │
│ (CDC ON)   │
└─────┬──────┘
      │  (logical replication / WAL)
      ▼
┌──────────────────┐
│  Debezium        │
│  (Kafka Connect) │
└─────┬────────────┘
      ▼
┌──────────────────┐
│   Kafka / MSK    │
│  (event log)     │
└─────┬────────────┘
      ▼
┌──────────────────┐
│ Snowflake BRONZE │  ← raw CDC events
└─────┬────────────┘
      ▼
┌──────────────────┐
│ dbt SILVER/GOLD  │
└─────┬────────────┘
      ▼
┌──────────────────┐
│ Power BI         │
└──────────────────┘

┌──────────────────┐
│ MWAA (Airflow)   │
│ - orchestration  │
│ - dbt runs       │
│ - monitoring     │
└──────────────────┘
```