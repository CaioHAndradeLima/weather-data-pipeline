{{
  config(
    materialized='incremental',
    unique_key='month',
    incremental_strategy='delete+insert'
  )
}}

with region_daily as (

    select
        observation_date,
        bool_or(was_raining) as region_was_raining
    from {{ ref('weather_daily_rain') }}

    {% if is_incremental() %}
    where observation_date >= (
        select min(month) from {{ this }}
    )
    {% endif %}

    group by observation_date
)

select
    date_trunc('month', observation_date) as month,
    count(*) filter (where region_was_raining) as rainy_days_in_month,
    count(*) as total_days_observed

from region_daily
group by date_trunc('month', observation_date)
order by month
