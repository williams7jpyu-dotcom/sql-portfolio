-- =====================================================
-- クエリ名: コホート別リテンションテーブル
-- ビジネス課題: コホート月 × 経過月 の2次元マトリクスで
--              「各コホートが何ヶ月後に何人残っているか」を集計する。
-- 使用テクニック: CTE, TIMESTAMPDIFF, 条件付き集計(CASE + COUNT DISTINCT)
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
),
order_cohort AS (
    SELECT
        fp.cohort_month,
        TIMESTAMPDIFF(MONTH, fp.first_order_date, o.order_date) AS month_offset,
        o.customer_id
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.status IN ('paid', 'shipped')
)
SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_offset = 0  THEN customer_id END) AS m0,
    COUNT(DISTINCT CASE WHEN month_offset = 1  THEN customer_id END) AS m1,
    COUNT(DISTINCT CASE WHEN month_offset = 2  THEN customer_id END) AS m2,
    COUNT(DISTINCT CASE WHEN month_offset = 3  THEN customer_id END) AS m3,
    COUNT(DISTINCT CASE WHEN month_offset = 4  THEN customer_id END) AS m4,
    COUNT(DISTINCT CASE WHEN month_offset = 5  THEN customer_id END) AS m5,
    COUNT(DISTINCT CASE WHEN month_offset = 6  THEN customer_id END) AS m6,
    COUNT(DISTINCT CASE WHEN month_offset >= 7 THEN customer_id END) AS m7plus
FROM order_cohort
GROUP BY cohort_month
ORDER BY cohort_month;
