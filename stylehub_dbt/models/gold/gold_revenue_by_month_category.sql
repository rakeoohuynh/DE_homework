-- INNER JOIN fact_orders: cần order_status và created_at để lọc đơn 
-- và xác định tháng; món hàng không có đơn thì không dùng được nên bỏ
-- LEFT JOIN dim_products: giữ mọi món hàng để revenue không bị thiếu; 
-- sản phẩm không khớp sẽ có category NULL và bị test not_null bắt

select 
        DATE_TRUNC(o.order_date, MONTH) as order_month,
        p.category as category, 
        COUNT(DISTINCT(o.order_id)) as total_orders,
        SUM(i.amount) as revenue, 
        SUM(i.amount-i.total_cost) as profit
from  {{ ref('fact_order_items') }} as i
join {{ ref('fact_orders') }} as o 
    on i.order_id = o.order_id 
left join {{ ref('dim_products') }} as p
    on i.product_id = p.product_id
where o.order_status not in ('Cancelled','Returned')
group by order_month,p.category
