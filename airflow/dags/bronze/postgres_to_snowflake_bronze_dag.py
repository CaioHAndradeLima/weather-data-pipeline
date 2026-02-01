import os
from datetime import datetime

from airflow.decorators import dag, task
from airflow.models import Variable
from airflow.models.param import Param
from dotenv import load_dotenv
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.airbyte.sensors.airbyte import AirbyteJobSensor
from airflow.utils.trigger_rule import TriggerRule
from airflow.decorators import task_group
from datetime import timedelta

from src.ingestion.airbyte.client import AirbyteClient
from src.ingestion.airbyte.discovery import discover_connections
from src.ingestion.airbyte.sync import sync_connection

load_dotenv()


@dag(
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["bronze", "airbyte"],
    max_active_tasks=1,
    default_args={"owner": "airflow"},
    params={
        "tables": Param(
            default=[],
            type="array",
            description="List of table names to sync (empty = all tables)",
        )
    },
)
def postgres_to_snowflake_bronze():

    @task
    def list_connections(params=None):
        tables = params.get("tables") if params else []

        client = AirbyteClient(
            base_url=os.getenv("AIRBYTE_API_URL"),
            workspace_id=os.getenv("WORKSPACE_ID"),
        )

        connections = discover_connections(client, tables)
        return [c["connectionId"] for c in connections]

    connection_ids = list_connections()

    @task_group()
    def airbyte_connection_group(connection_id: str):
        sync = AirbyteTriggerSyncOperator(
            task_id="sync",
            airbyte_conn_id="airbyte_default",
            connection_id=connection_id,
            asynchronous=True,
            pool="airbyte_sequential",
        )

        sensor = AirbyteJobSensor(
            task_id="sensor",
            airbyte_conn_id="airbyte_default",
            airbyte_job_id=sync.output,
            pool="airbyte_sequential",
            poke_interval= 30,
            timeout=60 * 60 * 60,
            retries=5,
            retry_delay= timedelta(minutes=5),
        )

        sync >> sensor

    airbyte_connection_group.expand(connection_id=connection_ids)


dag = postgres_to_snowflake_bronze()
