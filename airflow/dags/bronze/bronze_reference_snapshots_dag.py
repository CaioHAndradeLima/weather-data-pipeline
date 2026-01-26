from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator

from src.ingestion.postgres.snapshot.snapshot_reader import fetch_table
from src.ingestion.postgres.snapshot.snapshot_mapper import (
    write_customers_snapshot,
    write_products_snapshot,
)


def ingest_snapshots():
    customers = fetch_table("customers")
    products = fetch_table("products")

    write_customers_snapshot(customers)
    write_products_snapshot(products)


with DAG(
    dag_id="bronze_reference_snapshots",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    max_active_runs=1,
    tags=["bronze", "snapshot", "reference"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")
    ingest_task = PythonOperator(
        task_id="ingest_reference_snapshots",
        python_callable=ingest_snapshots,
    )
    start >> ingest_task >> end
