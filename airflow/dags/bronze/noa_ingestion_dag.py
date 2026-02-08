from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

from src.ingestion.noaa.noaa_observations_ingest import ingest_noaa_observations

default_args = {
    "owner": "data-eng",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="noaa_weather_observations",
    start_date=datetime(2024, 1, 1),
    schedule_interval="*/15 * * * *",
    catchup=False,
    default_args=default_args,
    tags=["weather", "noaa"],
) as dag:

    ingest = PythonOperator(
        task_id="ingest_noaa_observations",
        python_callable=ingest_noaa_observations,
    )

    ingest
