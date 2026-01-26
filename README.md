# Retail Data Pipeline

[![Retail Data Pipeline](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml)

## Overview

This project simulates a real-world retail data platform using a hybrid **local + cloud** architecture. It demonstrates
how to ingest, process, and analyze retail data using both **batch ingestion** and **Change Data Capture (CDC)**,
following the **Medallion Architecture (Bronze, Silver, Gold)** on Snowflake.

The platform is designed to answer typical business questions such as:

- How many orders are created per day?
- How much revenue is generated?
- What is the order conversion rate?
- Which products generate the most revenue?
- What percentage of orders are canceled or refunded?
- How long does it take for an order to move from created to shipped to delivered?

CDC is enabled for the `orders` table in the OLTP database. All other tables are ingested using a batch approach.

---

## High-Level Architecture

```
                     ┌──────────────────────┐
                     │   Source Systems     │
                     │ Postgres OLTP / CDC  │
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
```

---

## Snowflake Lakehouse and Medallion Architecture

Snowflake is used as the analytical lakehouse, structured using the Medallion Architecture:

| Layer  | Responsibility                   | Tooling         |
|--------|----------------------------------|-----------------|
| Bronze | Raw data ingestion (batch + CDC) | Python, Airflow |
| Silver | Cleansed and normalized data     | dbt             |
| Gold   | Business-ready marts and metrics | dbt             |
| Infra  | Warehouses, schemas, roles       | Terraform, Bash |
| BI     | Analytics and reporting          | Power BI        |

All Snowflake infrastructure (databases, schemas, warehouses, roles) can be created automatically using the `setup.sh`
script.

---

## Infrastructure Overview (Infrastructure as Code)

This project uses a hybrid infrastructure model:

- **Local environment**: fully containerized simulation of a production data platform
- **Remote environment (AWS)**: Snowflake analytics platform

```
infra/
├── local/        # Local development & simulation environment
├── snowflake/    # Snowflake analytics platform (Medallion architecture)
└── remote/       # Cloud infrastructure (AWS)
```

### Local Environment

The local environment runs entirely on Docker and includes:

- PostgreSQL OLTP database with CDC enabled
- Kafka and Zookeeper
- Debezium for CDC
- Airflow for orchestration
- Sample data initialization

```
infra/local/
├── airflow/
│   ├── util/                       # Utility scripts
│   ├── validation/                 # Validation DAGs
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── init_connections.sh         # Snowflake connection bootstrap
│
├── postgres/
│   └── init/
│       ├── 01_wal_level_setup.sql
│       ├── 02_init_retail_oltp.sql
│       ├── 03_data.sql
│       ├── 04_cdc.sql
│       └── 05_debezium_user.sql
│
├── kafka/
│   ├── connectors/
│   │   ├── debezium-postgres.json
│   │   └── register.sh
│   └── docker-compose.yml
│
├── start_containers.sh
├── stop_containers.sh
└── insert_new_order.sh
```

---

## Snowflake Analytics Platform (Terraform)

This module defines all Snowflake resources required to support the Medallion Architecture.

Responsibilities:

- Create databases and schemas
- Configure warehouses
- Define Bronze tables (batch and CDC)
- Manage roles, grants, and permissions
- Prepare the environment for dbt transformations

```
infra/snowflake/
├── setup/
│   ├── generate_terraform_user.sh
│   ├── install_local_cli.sh
│   └── roles.sql
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

---

## Running the Project Locally

The entire project is designed to run using a single bootstrap script.

### Requirements

- macOS
- Docker (installed and running)
- Homebrew
- Python
- pip
- Snowflake account

### Execution

```bash
chmod +x setup.sh
./setup.sh
```

The script performs the following steps:

1. Validates local prerequisites
2. Creates Snowflake infrastructure using Terraform
3. Bootstraps Snowflake users and roles
4. Starts the local Docker-based environment
5. Launches Airflow and supporting services

---

## CDC Implementation Notes

Currently, CDC events are consumed using custom Python code orchestrated by Airflow. While functional, this approach has
limitations compared to managed CDC tools.

| Feature            | Python + Airflow                   | Kafka Connect / Airbyte         |
|--------------------|------------------------------------|---------------------------------|
| Duplicate handling | Manual logic                       | Built-in exactly-once semantics |
| Latency            | Micro-batch                        | Near real-time                  |
| Complexity         | Low                                | Medium                          |
| CDC semantics      | Manual handling of updates/deletes | Native Debezium support         |

A future improvement would be migrating CDC ingestion to Kafka Connect or Airbyte.

---

## dbt Execution Strategy

This project uses **CLI-based dbt orchestration** instead of task-per-model orchestration.

| Aspect              | CLI-based dbt                 | dbt Cosmos            |
|---------------------|-------------------------------|-----------------------|
| DAG complexity      | Low                           | High                  |
| Setup effort        | Minimal                       | Moderate to high      |
| Failure granularity | Pipeline-level                | Model-level           |
| Observability       | Limited                       | High                  |
| Local development   | Simple                        | More complex          |
| CI/CD friendliness  | High                          | Moderate              |
| Recommended for     | Portfolio, small to mid teams | Mature data platforms |

The chosen approach prioritizes simplicity, portability, and ease of local development, with a clear migration path to
dbt Cosmos if needed.

---

## Project Status

The project is fully functional and demonstrates end-to-end ingestion, transformation, and analytics using both batch
and CDC data flows. Ongoing improvements focus on hardening CDC ingestion and improving observability.

