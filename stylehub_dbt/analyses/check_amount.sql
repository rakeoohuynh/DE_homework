SELECT *
FROM {{ ref('fact_order_items') }}
WHERE amount != sale_price * quantity 