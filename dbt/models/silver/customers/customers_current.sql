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
