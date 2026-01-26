{{ config(materialized='incremental', unique_key='customer_id', schema='silver') }}

with ranked_snapshots as (

    select
        customer_id,
        name,
        email,
        country,
        created_at,
        snapshot_date,

        row_number() over (
            partition by customer_id
            order by snapshot_date desc
        ) as rn

    from {{ source('bronze', 'CUSTOMERS_SNAPSHOT') }}

    {% if is_incremental() %}
        where snapshot_date >
            (
                select coalesce(max(last_snapshot_date), '1900-01-01')
                from {{ this }}
            )
    {% endif %}

)

select
    customer_id,
    name,
    email,
    country,
    created_at,
    snapshot_date as last_snapshot_date

from ranked_snapshots
where rn = 1
