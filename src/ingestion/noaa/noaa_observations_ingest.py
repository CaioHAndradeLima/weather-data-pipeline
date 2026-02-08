import os
import json
import logging
from datetime import datetime
from typing import List

import requests
import psycopg2
import psycopg2.extras

# =========================
# CONFIG
# =========================

NOAA_BASE_URL = "https://api.weather.gov"
STATIONS = ["KJFK", "KLGA", "KTEB"]

POSTGRES_DSN = os.getenv(
    "POSTGRES_DSN",
    "dbname=weather user=weather_user password=weather_password host=host.docker.internal port=5433",
)

REQUEST_HEADERS = {
    "User-Agent": "weather-ingestion/1.0 (portfolio project)",
    "Accept": "application/geo+json",
}

# =========================
# HTTP CLIENT
# =========================

def fetch_observations(station_id: str) -> List[dict]:
    url = f"{NOAA_BASE_URL}/stations/{station_id}/observations"
    resp = requests.get(url, headers=REQUEST_HEADERS, timeout=30)
    resp.raise_for_status()
    return resp.json()["features"]


# =========================
# PARSING
# =========================

def parse_feature(feature: dict) -> dict:
    props = feature["properties"]
    coords = feature["geometry"]["coordinates"]

    def val(obj):
        return obj["value"] if obj else None

    return {
        "station_id": props["stationId"],
        "station_name": props.get("stationName"),
        "observation_time": props["timestamp"],

        "temperature_c": val(props.get("temperature")),
        "dewpoint_c": val(props.get("dewpoint")),
        "relative_humidity": val(props.get("relativeHumidity")),

        "wind_direction_deg": val(props.get("windDirection")),
        "wind_speed_kmh": val(props.get("windSpeed")),
        "wind_gust_kmh": val(props.get("windGust")),

        "barometric_pressure_pa": val(props.get("barometricPressure")),
        "visibility_m": val(props.get("visibility")),

        "precipitation_last_3h_mm": val(props.get("precipitationLast3Hours")),

        "weather_description": props.get("textDescription"),

        "longitude": coords[0],
        "latitude": coords[1],
        "elevation_m": val(props.get("elevation")),

        "payload": json.dumps(props),
    }


# =========================
# DATABASE
# =========================

INSERT_SQL = """
INSERT INTO weather.observations (
    station_id,
    station_name,
    observation_time,
    temperature_c,
    dewpoint_c,
    relative_humidity,
    wind_direction_deg,
    wind_speed_kmh,
    wind_gust_kmh,
    barometric_pressure_pa,
    visibility_m,
    precipitation_last_3h_mm,
    weather_description,
    longitude,
    latitude,
    elevation_m,
    payload
)
VALUES (
    %(station_id)s,
    %(station_name)s,
    %(observation_time)s,
    %(temperature_c)s,
    %(dewpoint_c)s,
    %(relative_humidity)s,
    %(wind_direction_deg)s,
    %(wind_speed_kmh)s,
    %(wind_gust_kmh)s,
    %(barometric_pressure_pa)s,
    %(visibility_m)s,
    %(precipitation_last_3h_mm)s,
    %(weather_description)s,
    %(longitude)s,
    %(latitude)s,
    %(elevation_m)s,
    %(payload)s
)
ON CONFLICT (station_id, observation_time) DO NOTHING;
"""


def insert_rows(rows: List[dict]):
    with psycopg2.connect(POSTGRES_DSN) as conn:
        with conn.cursor() as cur:
            psycopg2.extras.execute_batch(
                cur,
                INSERT_SQL,
                rows,
                page_size=500,
            )
        conn.commit()


# =========================
# ingest_noaa_observations
# =========================

def ingest_noaa_observations():
    total_inserted = 0

    for station in STATIONS:

        features = fetch_observations(station)
        rows = [parse_feature(f) for f in features]

        insert_rows(rows)
        total_inserted += len(rows)

