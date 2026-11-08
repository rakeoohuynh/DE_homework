select
    id as product_id,
    name,
    brand,
    category,
    department,
    sku,
    cost,
    retail_price
from {{ ref('products_snapshot') }}
where valid_to is null