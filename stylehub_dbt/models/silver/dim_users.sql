with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'users') }}
)

select
    id as user_id,
    first_name,
    last_name,
    email,
    age,
    gender,
    country,
    state,
    city,
    street_address,
    postal_code,
    latitude,
    longitude,
    traffic_source
from ranked
where rn = 1
