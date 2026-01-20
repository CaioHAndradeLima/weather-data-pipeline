import psycopg2
from airflow.hooks.base import BaseHook
from airflow.models import Variable


def fetch_updated_shipments():
    last_updated = Variable.get(
        "shipments_last_updated_at",
        default_var="1970-01-01T00:00:00Z",
    )

    conn = BaseHook.get_connection("postgres_retail")

    pg_conn = psycopg2.connect(
        host=conn.host,
        port=conn.port,
        dbname=conn.schema,
        user=conn.login,
        password=conn.password,
    )

    cursor = pg_conn.cursor()

    cursor.execute(
        """
        SELECT
            shipment_id,
            order_id,
            shipment_status,
            carrier,
            shipped_at,
            delivered_at,
            created_at,
            updated_at
        FROM retail.shipments
        WHERE updated_at > %s
        ORDER BY updated_at ASC
        """,
        (last_updated,),
    )

    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    cursor.close()
    pg_conn.close()

    return [dict(zip(columns, row)) for row in rows]
