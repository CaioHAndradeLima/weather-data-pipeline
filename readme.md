# Retail Data Pipeline

[![Retail Data Pipeline](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml)

> Generate a production‑grade, data‑driven ELT platform built from scratch only passing your snowflake credentials using
> setup.sh

### No UI Clicks ever.

<b>Everything</b> — sources, destinations, connections, syncs, and transformations — **is created programmatically**.

- **Postgres** (OLTP Production data source)
- **Airbyte** (ingestion + CDC)
- **Airflow** (orchestration & lineage)
- **dbt** (Silver & Gold transformations)
- **Snowflake** (Lakehouse + Medallion Architecture)

## You don’t scale pipelines. You scale patterns

You will generate your entire infra, <b>capable of deal 10 thousand new tables</b>, including all ingestion
configuration between production source and Snowflake/Bronze, <b>without any effort</b>. You only need run `setup.sh`.

```bash
./setup.sh execution

Collect your Snowflake credentials and save into .env
   │
   ▼
Create all Snowflake remote infrastructure via Terraform
   │
   ▼
Start Postgres db simulating real production environment 
(Replace with real db info if you have one)
   │
   ▼
Start Airbyte and connect with Postgres and Snowflake
   │
   ▼
Discovers Postgres tables automatically and generate a tables.json
   │
   ▼
Create all ingestion connection between Postgres-Snowflake based on tables.json
   │
   ▼
Start Airflow and add Airbyte as a new connection
   │
   ▼
Bronze/Silver/Gold DAG is ready to run
```
---

### Data‑Driven Orchestration through Dynamic Airbyte Sync


**Conceptual flow:**

```
    DAG started
        │
        ▼
recover airbyte connections
  tables/columns to sync 
        │
        ▼
[ trigger_connection_1 ]──sensor results──┐
[ trigger_connection_2 ]──sensor results──┼──► trigger_dbt_silver
[ trigger_connection_3 ]──sensor results──┘            │
                                                       ▼
                                                 trigger_dbt_gold
```


---

## Core Philosophy

> **You inform your Snowflake account once. The platform builds itself through setup script.**

- Discovers Airbyte connections programmatically
- Triggers all connections in parallel
- Waits for completion via sensors
- No manual Airbyte UI configuration
- No manual Airflow UI configuration
- No manual Bronze/Raw configuration.
- No more dags to add new tables.
- No hardcoded pipelines per table
- No fragile point‑to‑point DAGs
- No ingestion headaches.
- No dbt Bronze models are required (only for testing)

The system is **data‑driven**: adding a table is a configuration change, not a new pipeline.

---

## High‑Level Architecture

```
Postgres (OLTP)  ───────────┐
   │                        │
   │  CDC / Incremental     │
   ▼                        │
Airbyte (API‑driven)        │
   │                        │
   │  Bulk load + dedup     │
   ▼                        ┼──► Airbyte Orchestrator
Snowflake                   │
   ├── BRONZE               │
   ├── SILVER               │
   └── GOLD                 │
   │                        │
   ▼                        │
BI / Analytics  ────────────┘
```

---
## Continuous integration Flow

[![Retail Data Pipeline](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/CaioHAndradeLima/retail-data-pipeline/actions/workflows/ci.yml)

```
Lint Check  ────────────┐
   ├── Ruff             │
   │                    │
   ▼                    │
Formatting Check        │
   ├── Black            │
   │                    │
   ▼                    │
Validate Dag imports    │
   ├── Airflow          ┼──► Github Actions
   │                    │
   ▼                    │
Validate DBT            │
   ├── SILVER           │
   └── GOLD             │
   │                    │
   ▼                    │
BI / Analytics  ────────┘
```

---

## Ingestion Details

- Postgres tables are ingested via **Airbyte**
- Mix of **CDC** and **incremental batch**
- Deduplication handled by Airbyte (`append_dedup`)

---

## Retail Business Questions

The postgres used has tables and data designed to answer typical retail business questions such as:

- How many orders are created per day?
- How much revenue is generated?
- What is the order conversion rate?
- Which products generate the most revenue?
- What percentage of orders are canceled or refunded?
- How long does it take for an order to move from created from shipped to delivered?

CDC is enabled for the `orders` table in the OLTP database. All other tables are ingested using a batch approach.


## dbt Strategy

dbt is executed via **CLI orchestration**, intentionally simple:

| Approach         | Reason                     |
|------------------|----------------------------|
| CLI‑based dbt    | Low complexity, easy CI/CD |
| No Cosmos        | Avoid DAG explosion        |
| Layer‑level runs | Clear failure domains      |

---