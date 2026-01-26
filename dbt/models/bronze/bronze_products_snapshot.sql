{{ config(
    materialized = 'table',
    schema = 'bronze'
) }}

select
    cast(null as string)        as product_id,
    cast(null as string)        as product_name,
    cast(null as string)        as category,
    cast(null as number(10,2))  as price,
    cast(null as boolean)       as active,
    cast(null as date)          as snapshot_date,
    cast(null as timestamp_tz)  as ingested_at
where 1 = 0
