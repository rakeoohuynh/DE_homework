-- BT2: tổng amount của các món hàng phải khớp total_amount của đơn.
-- Test trả ra các đơn bị lệch. 0 dòng là đạt.

-- TODO 1: cộng amount của fact_order_items theo từng order_id (dùng CTE)

-- TODO 2: nối với fact_orders, giữ lại các đơn mà total_amount khác tổng ở trên
--         (đơn không có món hàng nào thì tính tổng là 0)

with item_amount as (
    select
        order_id,
        sum(amount) as items_amount
    from {{ ref('fact_order_items') }}
    group by order_id
)

select
    o.order_id,
    o.total_amount,
    coalesce(i.items_amount, 0) as items_amount
from {{ ref('fact_orders') }} as o
left join item_amount as i
    on i.order_id = o.order_id
where o.total_amount != coalesce(i.items_amount, 0)
