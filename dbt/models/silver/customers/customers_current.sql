{{ config(materialized='incremental', unique_key='customer_id', schema='SILVER') }}

with ranked_snapshots as (

    select
        customer_id,
        full_name,
        email,
        country,
        created_at,
        updated_at,

        row_number() over (
            partition by customer_id
            order by updated_at desc
        ) as rn

    from {{ source('bronze', 'CUSTOMERS') }}

    {% if is_incremental() %}
        where updated_at >
            (
                select coalesce(max(last_updated_at), '1900-01-01')
                from {{ this }}
            )
    {% endif %}

)

select
    customer_id,
    full_name,
    email,
    country,
    created_at,
    updated_at as last_updated_at

from ranked_snapshots
where rn = 1
