{{ config(materialized='incremental', unique_key='order_id', schema='SILVER') }}

with ranked_events as (

    select
        order_id,
        customer_id,
        order_status,
        order_total,
        currency,
        updated_at,

        row_number() over (
            partition by order_id
            order by updated_at desc
        ) as rn

    from {{ source('bronze', 'ORDERS') }}

    {% if is_incremental() %}
        where updated_at > (select max(last_updated_at) from {{ this }})
    {% endif %}

)

select
    order_id,
    customer_id,
    order_status,
    order_total,
    currency,
    updated_at as last_updated_at,

from ranked_events
where rn = 1
