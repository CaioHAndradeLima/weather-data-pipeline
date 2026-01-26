{{ config(
    schema = 'gold'
) }}


select
    date_trunc('day', last_updated_at) as order_date,

    count(distinct order_id) as total_orders,

    count(distinct case
        when order_status in ('canceled', 'refunded') then order_id
    end) as canceled_or_refunded_orders,

    count(distinct case
        when order_status in ('canceled', 'refunded') then order_id
    end)
    / nullif(count(distinct order_id), 0) as cancellation_rate

from {{ ref('orders_current') }}
group by 1
order by 1
