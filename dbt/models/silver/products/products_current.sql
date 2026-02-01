{{ config(materialized='incremental', unique_key='product_id', schema='SILVER') }}

with ranked_snapshots as (

    select
        product_id,
        product_name,
        category,
        price,
        active,
        updated_at,

        row_number() over (
            partition by product_id
            order by updated_at desc
        ) as rn

    from {{ source('bronze', 'PRODUCTS') }}

    {% if is_incremental() %}
        where updated_at > (select max(last_updated_at) from {{ this }})
    {% endif %}

)

select
    product_id,
    product_name,
    category,
    price,
    active,
    updated_at as last_updated_at

from ranked_snapshots
where rn = 1
