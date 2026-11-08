with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'order_items') }}
),

items as (
    select * from ranked where rn = 1
)

select
    items.id as order_item_id,
    items.order_id,
    items.product_id,
    dim_products.product_key,
    items.created_at,
    items.sale_price,
    items.quantity,
    items.amount,
    dim_products.cost * items.quantity as total_cost
from items
left join {{ ref('dim_products_type2') }} as dim_products
    on dim_products.product_id = items.product_id
   and items.created_at >= dim_products.valid_from
   and (dim_products.valid_to is null or items.created_at < dim_products.valid_to)