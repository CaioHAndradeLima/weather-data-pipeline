CREATE SCHEMA IF NOT EXISTS weather;

CREATE TABLE IF NOT EXISTS weather.observations (
    station_id TEXT NOT NULL,
    station_name TEXT,
    observation_time TIMESTAMPTZ NOT NULL,

    -- Core measurements
    temperature_c DOUBLE PRECISION,
    dewpoint_c DOUBLE PRECISION,
    relative_humidity DOUBLE PRECISION,

    wind_direction_deg DOUBLE PRECISION,
    wind_speed_kmh DOUBLE PRECISION,
    wind_gust_kmh DOUBLE PRECISION,

    barometric_pressure_pa DOUBLE PRECISION,
    visibility_m DOUBLE PRECISION,

    -- Precipitation
    precipitation_last_3h_mm DOUBLE PRECISION,

    -- Qualitative indicators
    weather_description TEXT,

    -- Geo
    longitude DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    elevation_m DOUBLE PRECISION,

    -- Raw & lineage
    payload JSONB NOT NULL,
    ingested_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT pk_weather_observations
        PRIMARY KEY (station_id, observation_time)
);
