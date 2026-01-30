import os
from datetime import datetime

from airflow.decorators import dag, task
from airflow.models import Variable
from airflow.models.param import Param
from dotenv import load_dotenv
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.airbyte.sensors.airbyte import AirbyteJobSensor

from src.ingestion.airbyte.client import AirbyteClient
from src.ingestion.airbyte.discovery import discover_connections
from src.ingestion.airbyte.sync import sync_connection

load_dotenv()


@dag(
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["bronze", "airbyte"],
    max_active_tasks=2,
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

    airbyte_sync = AirbyteTriggerSyncOperator.partial(
        task_id="airbyte_sync",
        airbyte_conn_id="airbyte_default",
        asynchronous=True,
    ).expand(
        connection_id=connection_ids
    )

    airbyte_sensor = AirbyteJobSensor.partial(
        task_id="airbyte_sensor",
        airbyte_conn_id="airbyte_default",
    ).expand(
        airbyte_job_id=airbyte_sync.output
    )

    airbyte_sync >> airbyte_sensor


dag = postgres_to_snowflake_bronze()
