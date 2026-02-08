from airflow.datasets import Dataset

WEATHER_BRONZE = Dataset("snowflake://Weather/Bronze")
WEATHER_SILVER = Dataset("snowflake://Weather/Silver")
WEATHER_GOLD = Dataset("snowflake://Weather/Gold")
