{{ config(
    materialized = 'table',
    schema = 'BRONZE'
) }}

select
    cast(null as string)        as customer_id,
    cast(null as string)        as name,
    cast(null as string)        as email,
    cast(null as string)        as country,
    cast(null as timestamp_tz)  as created_at,
    cast(null as date)          as snapshot_date,
    cast(null as timestamp_tz)  as ingested_at
where 1 = 0
