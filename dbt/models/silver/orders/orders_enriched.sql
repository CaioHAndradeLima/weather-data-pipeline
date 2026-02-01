{{ config(schema='SILVER') }}

select
    o.order_id,
    o.order_status,
    o.order_total,
    o.currency,
    o.last_updated_at,

    c.customer_id,
    c.full_name as customer_name,
    c.country,

    p.payment_status,
    p.payment_method,
    p.amount as payment_amount,

    s.shipment_status,
    s.carrier

from {{ ref('orders_current') }} o
left join {{ ref('customers_current') }} c
    on o.customer_id = c.customer_id
left join {{ ref('payments_current') }} p
    on o.order_id = p.order_id
left join {{ ref('shipments_current') }} s
    on o.order_id = s.order_id
where o.last_updated_at >= current_date - 180

