{{ config(
    schema = 'gold'
) }}
select
    o.order_id,

    o.last_updated_at as order_created_at,
    s.last_updated_at as shipment_updated_at,

    datediff(
        'hour',
        o.last_updated_at,
        s.last_updated_at
    ) as hours_to_ship

from {{ ref('orders_current') }} o
left join {{ ref('shipments_current') }} s
    on o.order_id = s.order_id
where s.shipment_status in ('shipped', 'delivered')
