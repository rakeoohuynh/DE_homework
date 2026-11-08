{# with ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by updated_at desc, ingested_at desc
        ) as rn
    from {{ ref('fact_order_items') }}
),

latest_orders as (
    select * from ranked where rn = 1
) #}


-- =====================================================================
-- daily_revenue (Gold)
-- Grain: mỗi dòng = 1 ngày đặt đơn (mỗi order_date đúng 1 dòng)
-- Nguồn: fact_order_items (Silver, đã dedup: mỗi order_item_id 1 dòng)
-- Materialization: table (cấu hình chung cho thư mục gold
--   trong dbt_project.yml, nên không cần config() ở đây)
-- =====================================================================




select
    order_date,
    count(distinct order_id) as total_orders,
    sum(amount) as revenue,
    sum(total_cost) as total_cost
from {{ ref('fact_order_items') }}
group by order_date