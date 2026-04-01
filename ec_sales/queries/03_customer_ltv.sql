-- =====================================================
-- クエリ名: 顧客LTV（生涯価値）分析
-- ビジネス課題: 顧客ごとの累計売上・注文回数・平均注文額を算出し、
--              VIP顧客の識別やCRM施策の優先度判定に活用する。
-- 使用テクニック: CTE（注文単位の小計を先に集計）, JOIN, 集計関数
-- 対象テーブル: orders, order_items, customers
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 注文単位で小計を算出（集計粒度を注文→顧客に上げる前処理）
WITH order_amounts AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS order_amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid','shipped')
    GROUP BY o.order_id, o.customer_id
)
-- Step 2: 顧客単位で集約し、LTV・注文回数・平均注文額を算出
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(oa.order_id)              AS order_count,
    SUM(oa.order_amount)            AS lifetime_value,
    ROUND(AVG(oa.order_amount), 2)  AS avg_order_value
FROM customers c
JOIN order_amounts oa ON c.customer_id = oa.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_value DESC
LIMIT 50;
