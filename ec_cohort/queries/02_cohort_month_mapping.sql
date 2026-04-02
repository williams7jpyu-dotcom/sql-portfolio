-- =====================================================
-- クエリ名: 購買月とコホート月のマッピング
-- ビジネス課題: 各注文にコホート月と「初回購買から何ヶ月後の購買か」
--              を付与し、リテンション集計の元データを作成する。
-- 使用テクニック: CTE, TIMESTAMPDIFF(MONTH), DATE_FORMAT
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month,
        MIN(order_date)                       AS first_order_date
    FROM orders
    WHERE status IN ('paid', 'shipped')
    GROUP BY customer_id
)
SELECT
    fp.cohort_month,
    DATE_FORMAT(o.order_date, '%Y-%m')                     AS order_month,
    TIMESTAMPDIFF(MONTH, fp.first_order_date, o.order_date) AS months_since_first,
    o.customer_id,
    o.order_id
FROM orders o
JOIN first_purchase fp ON o.customer_id = fp.customer_id
WHERE o.status IN ('paid', 'shipped')
ORDER BY fp.cohort_month, months_since_first, o.customer_id;
