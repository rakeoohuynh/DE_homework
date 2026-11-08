with versions as (
    select
        id as order_id,
        user_id,
        status as order_status,
        date(created_at) as order_date,
        total_amount,
        created_at,
        updated_at,
        _airbyte_extracted_at
    from {{ source('stylehub_bronze', 'orders') }}
),

compared as (
    select
        *,
        lag(order_status) over (
            partition by order_id
            order by updated_at, _airbyte_extracted_at
        ) as prev_status
    from versions
),

changed as (
    select *
    from compared
    where prev_status is null or prev_status != order_status
)

select
    order_id,
    user_id,
    order_status,
    order_date,
    total_amount,
    if(prev_status is null, created_at, updated_at) as valid_from,
    lead(updated_at) over (
        partition by order_id
        order by updated_at, _airbyte_extracted_at
    ) as valid_to,
    lead(updated_at) over (
        partition by order_id
        order by updated_at, _airbyte_extracted_at
    ) is null as is_current
from changed
