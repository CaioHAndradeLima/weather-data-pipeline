import psycopg2
from airflow.hooks.base import BaseHook


def fetch_table(table_name: str):
    conn = BaseHook.get_connection("postgres_retail")

    pg_conn = psycopg2.connect(
        host=conn.host,
        port=conn.port,
        dbname=conn.schema,
        user=conn.login,
        password=conn.password,
    )

    cursor = pg_conn.cursor()
    cursor.execute(f"SELECT * FROM retail.{table_name}")

    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    cursor.close()
    pg_conn.close()

    return [dict(zip(columns, row)) for row in rows]
