{{
  config(
    materialized='incremental',
    unique_key=['station_id', 'observation_date'],
    incremental_strategy='delete+insert'
  )
}}

select
    station_id,
    station_name,
    observation_date,

    bool_or(is_raining) as was_raining,
    sum(coalesce(precipitation_last_3h_mm, 0)) as total_precip_mm,

    min(observation_time_utc) as first_observation,
    max(observation_time_utc) as last_observation

from {{ ref('weather_observations_clean') }}

{% if is_incremental() %}
where observation_date >= (
    select max(observation_date) from {{ this }}
)
{% endif %}

group by
    station_id,
    station_name,
    observation_date
