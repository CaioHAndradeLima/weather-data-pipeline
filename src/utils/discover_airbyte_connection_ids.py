from airflow.decorators import task
from airflow.operators.python import get_current_context
import os

from src.ingestion.airbyte.client import AirbyteClient
from src.ingestion.airbyte.discovery import discover_connections


@task
def discover_airbyte_connection_ids() -> list[str]:
    """
    Discover Airbyte connection IDs using HTTP.
    """

    context = get_current_context()
    params = context["params"]
    tables = params.get("tables", [])

    client = AirbyteClient(
        base_url=os.getenv("AIRBYTE_API_URL"),
        workspace_id=os.getenv("WORKSPACE_ID"),
    )

    connections = discover_connections(client, tables)

    return [c["connectionId"] for c in connections]
