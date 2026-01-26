{{ config(
    schema = 'gold'
) }}

select
    date_trunc('day', last_updated_at) as revenue_date,
    sum(order_total) as total_revenue
from {{ ref('orders_current') }}
where order_status not in ('canceled', 'refunded')
group by 1
order by 1
