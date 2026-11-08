select
    scd_id as product_key,
    id as product_id,
    name,
    brand,
    category,
    department,
    sku,
    cost,
    retail_price,
    valid_from,
    valid_to,
    valid_to is null as is_current
from {{ ref('products_snapshot') }}