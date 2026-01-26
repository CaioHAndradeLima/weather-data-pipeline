from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator

from src.ingestion.postgres.incremental.payment_reader import (
    fetch_updated_payments,
)
from src.ingestion.postgres.incremental.payment_events_mapper import (
    map_and_write_payment_events,
)


def ingest_payments():
    rows = fetch_updated_payments()

    if not rows:
        return

    map_and_write_payment_events(rows)

    # Update watermark AFTER successful Snowflake write
    max_updated_at = max(row["updated_at"] for row in rows)
    Variable.set("payments_last_updated_at", max_updated_at.isoformat())


with DAG(
    dag_id="bronze_db_payment_events",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@hourly",
    catchup=False,
    max_active_runs=1,
    tags=["bronze", "postgres", "payments"],
) as dag:
    ingest_task = PythonOperator(
        task_id="ingest_payment_events",
        python_callable=ingest_payments,
    )
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")
    start >> ingest_task >> end
