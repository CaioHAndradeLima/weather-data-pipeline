from datetime import datetime

from airflow.operators.python import PythonOperator

from airflow import DAG
from src.ingestion.postgres.cdc.orders_cdc_consumer import consume_and_write_orders
from airflow.operators.empty import EmptyOperator

with DAG(
        dag_id="bronze_kafka_order_events",
        start_date=datetime(2024, 1, 1),
        schedule_interval="@hourly",
        catchup=False,
        max_active_runs=1,
        tags=["bronze", "kafka", "cdc"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    consume_task = PythonOperator(
        task_id="consume_order_events",
        python_callable=consume_and_write_orders,
    )

    start >> consume_task >> end
