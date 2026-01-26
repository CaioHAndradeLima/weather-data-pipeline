from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator

from src.ingestion.postgres.incremental.shipment_reader import (
    fetch_updated_shipments,
)
from src.ingestion.postgres.incremental.shipment_events_mapper import (
    map_and_write_shipment_events,
)


def ingest_shipments():
    rows = fetch_updated_shipments()

    if not rows:
        return

    map_and_write_shipment_events(rows)

    max_updated_at = max(row["updated_at"] for row in rows)
    Variable.set("shipments_last_updated_at", max_updated_at.isoformat())


with DAG(
    dag_id="bronze_db_shipment_events",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@hourly",
    catchup=False,
    max_active_runs=1,
    tags=["bronze", "postgres", "shipments"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    ingest_task = PythonOperator(
        task_id="ingest_shipment_events",
        python_callable=ingest_shipments,
    )

    start >> ingest_task >> end
