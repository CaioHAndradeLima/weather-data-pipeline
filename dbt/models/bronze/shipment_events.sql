{{ config(
    materialized = 'table',
    schema = 'BRONZE'
) }}

select
    cast(null as string)        as event_id,
    cast(null as string)        as event_type,
    cast(null as integer)       as event_version,
    cast(null as string)        as shipment_id,
    cast(null as string)        as order_id,
    cast(null as string)        as shipment_status,
    cast(null as string)        as carrier,
    cast(null as timestamp_tz)  as event_timestamp,
    cast(null as timestamp_tz)  as produced_at,
    cast(null as timestamp_tz)  as ingested_at,
    cast(null as string)        as source_system,
    cast(null as string)        as kafka_topic,
    cast(null as integer)       as kafka_partition,
    cast(null as integer)       as kafka_offset
where 1 = 0
