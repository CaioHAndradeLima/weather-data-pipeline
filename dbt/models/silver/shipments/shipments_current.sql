{{ config(materialized='incremental', unique_key='shipment_id', schema='SILVER') }}

with ranked_events as (

    select
        shipment_id,
        order_id,
        shipment_status,
        carrier,
        updated_at,

        row_number() over (
            partition by shipment_id
            order by updated_at desc
        ) as rn

    from {{ source('bronze', 'SHIPMENTS') }}

    {% if is_incremental() %}
        where updated_at > (select max(last_updated_at) from {{ this }})
    {% endif %}
)

select
    shipment_id,
    order_id,
    shipment_status,
    carrier,
    updated_at as last_updated_at

from ranked_events
where rn = 1
