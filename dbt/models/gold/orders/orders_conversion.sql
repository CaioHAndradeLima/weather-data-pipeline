{{ config(
    schema = 'gold'
) }}

select
    date_trunc('day', o.last_updated_at) as order_date,

    count(distinct o.order_id) as total_orders,

    count(distinct case
        when p.payment_status = 'paid' then o.order_id
    end) as converted_orders,

    count(distinct case
        when p.payment_status = 'paid' then o.order_id
    end)
    / nullif(count(distinct o.order_id), 0) as conversion_rate

from {{ ref('orders_current') }} o
left join {{ ref('payments_current') }} p
    on o.order_id = p.order_id
group by 1
order by 1
