{{ config(materialized='incremental', unique_key='product_id', schema='silver') }}

with ranked_snapshots as (

    select
        product_id,
        product_name,
        category,
        price,
        active,
        snapshot_date,

        row_number() over (
            partition by product_id
            order by snapshot_date desc
        ) as rn

    from {{ source('bronze', 'PRODUCTS_SNAPSHOT') }}

    {% if is_incremental() %}
        where snapshot_date > (select max(last_snapshot_date) from {{ this }})
    {% endif %}

)

select
    product_id,
    product_name,
    category,
    price,
    active,
    snapshot_date as last_snapshot_date

from ranked_snapshots
where rn = 1
