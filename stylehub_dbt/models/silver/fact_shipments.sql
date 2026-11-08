{{ config(
    materialized='incremental',
    unique_key='shipment_id'
) }}

with ranked as (
    select
        s.*,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'shipments') }} as s
    {% if is_incremental() %}
    where s.updated_at >= (select max(updated_at) from {{ this }})
    {% endif %}
)

select
    id as shipment_id,
    order_id,
    shipped_at,
    delivered_at,
    returned_at,
    updated_at
from ranked
where rn = 1