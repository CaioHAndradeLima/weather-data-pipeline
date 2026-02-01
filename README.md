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

# Data Platform – Automated Postgres → Snowflake Pipeline

This project implements a **fully automated, scalable ELT data platform** using **Postgres, Airbyte, Airflow, dbt, and Snowflake**.

The core idea is simple:

> **You declare your source tables once — everything else (connections, syncs, orchestration, transformations) is generated and executed automatically.**

---

## High-Level Architecture

```
                     ┌──────────────────────┐
                     │   Source Systems     │
                     │  Postgres (OLTP)     │
                     └──────────┬───────────┘
                                │
                                │  CDC / Incremental
                                │
                        ┌───────▼────────┐
                        │   Airbyte       │
                        │ (Ingestion)     │
                        └───────┬────────┘
                                │
                                │ Raw replication
                                │
                    ┌───────────▼────────────┐
                    │ Snowflake               │
                    │ BRONZE                  │
                    │ Raw / CDC tables        │
                    └───────────┬────────────┘
                                │
                               dbt
                                │
                    ┌───────────▼────────────┐
                    │ Snowflake               │
                    │ SILVER                  │
                    │ Clean / Normalized      │
                    └───────────┬────────────┘
                                │
                               dbt
                                │
                    ┌───────────▼────────────┐
                    │ Snowflake               │
                    │ GOLD                    │
                    │ Business Marts          │
                    └───────────┬────────────┘
                                │
                          BI / Analytics
```

---

## Execution Flow (End-to-End)

```
Postgres
   │
   │ 1️⃣ Schema & table discovery
   ▼
Airbyte API (scripts)
   │
   │ 2️⃣ Auto-create Sources & Destinations
   │ 3️⃣ Auto-generate table mappings
   ▼
Airbyte Connections
   │
   │ 4️⃣ Trigger syncs programmatically
   ▼
Airflow (Master DAG)
   │
   │ 5️⃣ Orchestrate ingestion
   ▼
dbt (Silver & Gold)
```

---

## Local infra Structure

```
infra
├── airbyte/
│   ├── brew_install_airbyte_abctl.sh
│   ├── start_airbyte.sh
│   ├── setup_postgres_source.sh
│   ├── setup_snowflake_destination.sh
│   ├── generate_tables_json.sh
│   ├── create_connections.sh
│   └── tables.json
│
├── airflow/
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── init_connections.sh
│   ├── util/
│   └── validation/
│
├── postgres/
│   ├── docker-compose.yml
│   └── init/
│
├── start_containers.sh
└── stop_containers.sh
```

---

## Fully Automated Setup

### 2️⃣ Automatic Postgres Source Creation (CDC)

The script `setup_postgres_source.sh`:

- Connects to the **Airbyte API**
- Creates a **Postgres source**
- Enables **CDC replication**
- Configures replication slot & publication

Example:

```json
"replication_method": {
  "method": "CDC",
  "replication_slot": "airbyte_slot",
  "publication": "airbyte_publication"
}
```

No manual UI steps required at all.

---

### 3️⃣ Automatic Snowflake Destination Setup

A dedicated script:
- Creates the Snowflake destination
- Configures warehouse, database, schema
- Stores the destination ID for reuse

---

### 4️⃣ Dynamic Table Discovery & Mapping

The script `generate_tables_json.sh`:

- Reads the **Airbyte catalog**
- Detects:
  - Schemas
  - Tables
  - Primary keys
- Generates `tables.json` automatically

Example output:

```json
{
  "name": "customers_postgres_to_snowflake",
  "tables": [
    {
      "name": "customers",
      "namespace": "retail",
      "sync_mode": "incremental",
      "destination_sync_mode": "append_dedup",
      "primary_key": ["customer_id"]
    }
  ]
}
```


**To add a new table:**
- Add it to Postgres and re-run the script or add a new item into the `tables.json` file
- Done.

---

### Connection Creation (Mass-Scale)

`create_connections.sh`:

- Reads `tables.json`
- Creates **one Airbyte connection per table**
- Applies best practices:
  - Incremental sync
  - Deduplication
  - Primary key aware

This makes the system **horizontally scalable**.

---

## 🧩 Orchestration with Airflow

Airflow owns **execution**, not configuration.

### Master DAG

```python
@dag(schedule="@daily", catchup=False)
def postgres_to_snowflake_bronze():

    @task
    def list_connections(params=None):
        connections = discover_connections(client, tables)
        return [c["connectionId"] for c in connections]

    @task
    def sync(connection_id: str):
        sync_connection(client, connection_id)

    sync.expand(connection_id=list_connections())
```

### What this gives you:
- Dynamic task mapping
- Parallel ingestion
- Table-level isolation
- Easy re-runs

---

## 🧪 Transformations (dbt)

After ingestion:

- **BRONZE** → raw Airbyte output
- **SILVER** → cleaned & normalized
- **GOLD** → analytics-ready marts

Airflow can trigger dbt runs after ingestion.

---

## Key Benefits

Fully automated

Declarative table management

Scales to hundreds of tables

No Airbyte UI dependency

Production-ready CDC

Clear separation of concerns

---

## 🧠 Mental Model

> **Postgres schema = source of truth**
>
> Everything else is derived automatically.

You don’t manage pipelines.

You manage **data models**.

---

## 🏁 TL;DR

- Add or change tables in Postgres
- Re-run scripts
- Airbyte connections regenerate
- Airflow orchestrates syncs
- dbt builds analytics layers

🚀 **Zero-click ingestion at scale

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
## Snowflake Analytics Platform (Terraform)

This module defines all Snowflake resources required to support the Medallion Architecture.

Responsibilities:

- Create databases and schemas
- Configure warehouses
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

## Sensors planing

```bash

list_connections
        |
   ┌───────────────┐
   │  connection A │─── sync ── sensor
   └───────────────┘
   ┌───────────────┐
   │  connection B │─── sync ── sensor
   └───────────────┘
   ┌───────────────┐
   │  connection C │─── sync ── sensor
   └───────────────┘
```
