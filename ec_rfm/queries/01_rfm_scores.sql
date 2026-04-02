-- =====================================================
-- クエリ名: RFMスコア算出
-- ビジネス課題: 顧客ごとの最終購買日(R)・購買回数(F)・
--              累計購買金額(M)を集計し、RFM分析の基礎データを作成する。
-- 使用テクニック: CTE, DATEDIFF, CURDATE(), SUM, COUNT
-- 実行環境: MySQL 8.0+
-- 対象テーブル: ec_sales の customers / orders / order_items を参照
-- =====================================================

WITH customer_orders AS (
    SELECT
        o.customer_id,
        MAX(o.order_date)                AS last_order_date,
        COUNT(DISTINCT o.order_id)       AS frequency,
        SUM(oi.quantity * oi.unit_price)  AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid', 'shipped')
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    co.last_order_date,
    DATEDIFF(CURDATE(), co.last_order_date) AS recency_days,
    co.frequency,
    co.monetary
FROM customers c
JOIN customer_orders co ON c.customer_id = co.customer_id
ORDER BY co.monetary DESC;
