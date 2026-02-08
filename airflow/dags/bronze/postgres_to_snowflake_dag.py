from datetime import datetime
from airflow import DAG
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from dotenv import load_dotenv

from src.ingestion.airbyte.tasks import list_connections
from src.ingestion.airbyte.task_groups import airbyte_connection_group
from src.lineage.datasets import WEATHER_BRONZE

load_dotenv()


with DAG(
    dag_id="postgres_to_snowflake_bronze",
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
    is_paused_upon_creation=False,
) as dag:

    start = EmptyOperator(task_id="start")
    end = EmptyOperator(
        task_id="Trigger_DBT_Silver",
        outlets=[WEATHER_BRONZE],
    )

    connections = list_connections()

    mapped_airbyte_group = airbyte_connection_group.expand_kwargs(connections)

    start >> connections >> mapped_airbyte_group >> end
