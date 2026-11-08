-- =====================================================================
-- fact_order_items (Silver)
-- Grain: mỗi dòng = 1 order item (mỗi order_item_id đúng 1 dòng)
-- Nguồn: source order_items (Bronze) + fact_orders + dim_products
-- =====================================================================

-- CTE 1: ranked
-- Bronze order_items có thể chứa nhiều phiên bản của cùng 1 item
-- (mỗi lần Airbyte sync / cập nhật sinh thêm 1 dòng).
-- Macro latest_rank() sinh ROW_NUMBER() partition theo id,
-- sắp updated_at DESC rồi _airbyte_extracted_at DESC
-- -> phiên bản mới nhất của mỗi item có rn = 1.
with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'order_items') }}
),

-- CTE 2: items
-- Giữ phiên bản mới nhất (rn = 1) -> mỗi item còn 1 dòng.
-- Đổi tên id -> order_item_id và chỉ lấy các cột cần dùng.
-- (Phải lọc rn ở CTE sau vì WHERE chạy trước SELECT,
--  nên không lọc được rn ngay trong CTE đã tạo ra nó.)
items as (
    select
        id as order_item_id,
        order_id,
        product_id,
        sale_price,
        quantity,
        amount
    from ranked
    where rn = 1
),

-- CTE 3: ranked_orders
-- fact_orders giữ MỖI PHIÊN BẢN của đơn 1 dòng
-- (order_key = id + created_at + updated_at, đổi status là thêm dòng mới).
-- Nếu JOIN thẳng fact_orders theo order_id -> 1 item khớp nhiều phiên bản
-- -> nhân dòng (join fan-out). Vì vậy đánh số các phiên bản theo order_id.
-- Không dùng macro latest_rank được vì fact_orders không có cột
-- _airbyte_extracted_at (đã đổi tên thành ingested_at).
ranked_orders as (
    select
        *,
        row_number() over (
            partition by order_id
            order by updated_at desc, ingested_at desc
        ) as rn
    from {{ ref('fact_orders') }}
),

-- CTE 4: latest_orders
-- Giữ phiên bản mới nhất của mỗi đơn -> mỗi order_id còn đúng 1 dòng.
latest_orders as (
    select * from ranked_orders where rn = 1
)

-- Final SELECT
-- items JOIN latest_orders: cả 2 phía đều 1 dòng/khóa -> không fan-out.
--   INNER JOIN: item nào không có đơn tương ứng sẽ bị loại.
-- LEFT JOIN dim_products: giữ item kể cả khi không tìm thấy sản phẩm;
--   khi đó cost = NULL -> total_cost = NULL (SUM ở Gold sẽ bỏ qua).
-- total_cost = giá vốn 1 sản phẩm * số lượng.
select
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.user_id,
    o.order_status,
    o.order_date,
    i.sale_price,
    i.quantity,
    i.amount,
    p.cost * i.quantity as total_cost
from items as i
join latest_orders as o
    on i.order_id = o.order_id
left join {{ ref('dim_products') }} as p
    on i.product_id = p.product_id
