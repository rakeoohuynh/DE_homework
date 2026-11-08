with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'products') }}
)

select
    id as product_id,
    name as product_name,
    category,
    brand,
    department,
    sku,
    cost,
    retail_price
from ranked
where rn = 1
