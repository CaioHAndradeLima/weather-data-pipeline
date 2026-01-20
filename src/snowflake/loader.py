import json
import logging
import tempfile
from typing import List, Dict

from src.snowflake.connection import get_snowflake_connection

logger = logging.getLogger(__name__)


def snowflake_bulk_insert(
    *,
    table_name: str,
    records: List[Dict],
    database: str,
    schema: str,
    warehouse: str,
) -> None:
    """
    Generic bulk insert into Snowflake using PUT + COPY INTO.

    Assumes:
      - records are dicts with keys matching column names
      - append-only semantics
    """

    if not records:
        return

    # 1️⃣ Write records as JSON lines
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        for record in records:
            f.write(json.dumps(record) + "\n")
        file_path = f.name

    conn = get_snowflake_connection(
        database=database,
        schema=schema,
        warehouse=warehouse,
    )

    cursor = conn.cursor()

    try:
        # 2️⃣ Upload file to table stage
        cursor.execute(
            f"PUT file://{file_path} @%{table_name} AUTO_COMPRESS=TRUE"
        )

        # 3️⃣ Copy into table
        cursor.execute(
            f"""
            COPY INTO {table_name}
            FROM @%{table_name}
            FILE_FORMAT = (TYPE = JSON)
            MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
            """
        )

    except Exception:
        logger.exception("Snowflake bulk insert failed")
        raise

    finally:
        cursor.close()
        conn.close()
