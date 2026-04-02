-- =====================================================
-- クエリ名: 離脱リスク顧客一覧
-- ビジネス課題: 最終購買から90日以上経過している顧客を抽出し、
--              フォローアップ施策（リマインドメール等）の対象を特定する。
-- 使用テクニック: CTE, DATEDIFF, CURDATE(), HAVING
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH customer_activity AS (
    SELECT
        o.customer_id,
        MAX(o.order_date)                       AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))  AS days_since_last,
        COUNT(DISTINCT o.order_id)              AS total_orders,
        SUM(oi.quantity * oi.unit_price)         AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid', 'shipped')
    GROUP BY o.customer_id
    HAVING DATEDIFF(CURDATE(), MAX(o.order_date)) >= 90
)
SELECT
    c.customer_id,
    c.customer_name,
    c.email,
    ca.last_order_date,
    ca.days_since_last,
    ca.total_orders,
    ca.total_spent,
    CASE
        WHEN ca.total_spent >= 30000 THEN '高LTV — 優先フォロー'
        WHEN ca.total_orders >= 3    THEN 'リピーター — 再活性化施策'
        ELSE '一般 — 標準リマインド'
    END AS follow_up_priority
FROM customer_activity ca
JOIN customers c ON ca.customer_id = c.customer_id
ORDER BY ca.total_spent DESC;
