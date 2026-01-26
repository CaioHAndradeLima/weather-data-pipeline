{{ config(materialized='incremental', unique_key='shipment_id', schema='silver') }}

with ranked_events as (

    select
        shipment_id,
        order_id,
        shipment_status,
        carrier,
        event_timestamp,

        row_number() over (
            partition by shipment_id
            order by event_timestamp desc
        ) as rn

    from {{ source('bronze', 'SHIPMENT_EVENTS') }}

    {% if is_incremental() %}
        where event_timestamp > (select max(last_updated_at) from {{ this }})
    {% endif %}
)

select
    shipment_id,
    order_id,
    shipment_status,
    carrier,
    event_timestamp as last_updated_at

from ranked_events
where rn = 1
