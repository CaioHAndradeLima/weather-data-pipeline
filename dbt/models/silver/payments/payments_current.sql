with ranked_events as (

    select
        payment_id,
        order_id,
        payment_status,
        payment_method,
        amount,
        currency,
        event_timestamp,

        row_number() over (
            partition by payment_id
            order by event_timestamp desc
        ) as rn

    from {{ source('bronze', 'PAYMENT_EVENTS') }}
)

select
    payment_id,
    order_id,
    payment_status,
    payment_method,
    amount,
    currency,
    event_timestamp as last_updated_at

from ranked_events
where rn = 1
