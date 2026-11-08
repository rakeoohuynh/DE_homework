with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'order_items') }}
),

items as (
    select
        id as order_item_id,
        order_id,
        product_id,
        quantity,
        amount
    from ranked
    where rn = 1
)

select
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.order_date,
    i.quantity,
    i.amount,
    p.cost as cost_at_order,
    p.cost * i.quantity as total_cost
from items as i
join {{ ref('fact_orders') }} as o
    on i.order_id = o.order_id
left join {{ ref('dim_products_scd2') }} as p
    on i.product_id = p.product_id
    and o.order_date >= date(p.valid_from)
    and (p.valid_to is null or o.order_date < date(p.valid_to))
