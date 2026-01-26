{{ config(materialized='incremental', unique_key='payment_id', schema='silver') }}

with ranked_events as (

    select
        payment_id,
        order_id,
        payment_status,
        payment_method,
        amount,
        currency,
        event_timestamp,
        ingested_at,

        row_number() over (
            partition by payment_id
            order by ingested_at desc
        ) as rn

    from {{ source('bronze', 'PAYMENT_EVENTS') }}

    {% if is_incremental() %}
        where ingested_at > (select max(last_ingested_at) from {{ this }})
    {% endif %}
)

select
    payment_id,
    order_id,
    payment_status,
    payment_method,
    amount,
    currency,
    event_timestamp as last_updated_at,
    ingested_at as last_ingested_at

from ranked_events
where rn = 1
