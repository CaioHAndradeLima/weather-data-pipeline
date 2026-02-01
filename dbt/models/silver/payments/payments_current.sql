{{ config(materialized='incremental', unique_key='payment_id', schema='SILVER') }}

with ranked_events as (

    select
        payment_id,
        order_id,
        payment_status,
        payment_method,
        amount,
        currency,
        updated_at,

        row_number() over (
            partition by payment_id
            order by updated_at desc
        ) as rn

    from {{ source('bronze', 'PAYMENTS') }}

    {% if is_incremental() %}
        where updated_at > (select max(last_ingested_at) from {{ this }})
    {% endif %}
)

select
    payment_id,
    order_id,
    payment_status,
    payment_method,
    amount,
    currency,
    updated_at as last_ingested_at

from ranked_events
where rn = 1
