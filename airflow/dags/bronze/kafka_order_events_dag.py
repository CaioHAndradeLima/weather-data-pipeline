# airflow/dags/bronze/kafka_order_events_dag.py

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from src.ingestion.kafka.consumer import consume_order_events

with DAG(
    dag_id="bronze_kafka_order_events",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@hourly",
    catchup=False,
) as dag:

    consume_task = PythonOperator(
        task_id="consume_order_events",
        python_callable=consume_order_events,
    )
