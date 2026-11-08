{{ config(materialized='ephemeral') }}

-- Bản mới nhất của mỗi sản phẩm. Snapshot đọc model này thay vì đọc source trực tiếp.
with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'products') }}
)

select
    id,
    name,
    brand,
    category,
    department,
    sku,
    cost,
    retail_price,
    updated_at
from ranked
where rn = 1