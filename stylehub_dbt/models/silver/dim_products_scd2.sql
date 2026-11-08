with versions as (
    select
        id as product_id,
        name as product_name,
        category,
        brand,
        department,
        sku,
        cost,
        retail_price,
        created_at,
        updated_at,
        _airbyte_extracted_at,
        to_hex(md5(to_json_string(
            struct(cost, category, name, brand, retail_price, department, sku)
        ))) as row_hash
    from {{ source('stylehub_bronze', 'products') }}
),

compared as (
    select
        *,
        lag(row_hash) over (
            partition by product_id
            order by updated_at, _airbyte_extracted_at
        ) as prev_hash
    from versions
),

changed as (
    select *
    from compared
    where prev_hash is null or prev_hash != row_hash
)

select
    product_id,
    product_name,
    category,
    brand,
    department,
    sku,
    cost,
    retail_price,
    if(prev_hash is null, created_at, updated_at) as valid_from,
    lead(updated_at) over (
        partition by product_id
        order by updated_at, _airbyte_extracted_at
    ) as valid_to,
    lead(updated_at) over (
        partition by product_id
        order by updated_at, _airbyte_extracted_at
    ) is null as is_current
from changed
