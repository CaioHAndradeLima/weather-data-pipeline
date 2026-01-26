{{ config(
    schema = 'gold'
) }}

select
    date_trunc('day', last_updated_at) as order_date,
    count(distinct order_id) as orders_created
from {{ ref('orders_current') }}
group by 1
order by 1
