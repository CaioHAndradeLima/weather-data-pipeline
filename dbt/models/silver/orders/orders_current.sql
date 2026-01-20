with ranked_events as (

    select
        event_id,
        order_id,
        customer_id,
        order_status,
        order_total,
        currency,
        event_type,
        event_timestamp,
        produced_at,
        ingested_at,

        row_number() over (
            partition by order_id
            order by event_timestamp desc
        ) as rn

    from {{ source('bronze', 'ORDER_EVENTS') }}
    where order_id is not null
)

select
    order_id,
    customer_id,
    order_status,
    order_total,
    currency,
    event_timestamp as last_updated_at,
    event_type as last_event_type,
    produced_at,
    ingested_at

from ranked_events
where rn = 1
