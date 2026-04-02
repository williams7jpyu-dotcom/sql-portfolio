-- =====================================================
-- クエリ名: コホート別リテンション率（%）
-- ビジネス課題: 初月(m0)の顧客数を分母にして各月の残存率を算出し、
--              「どのコホートがどの時点で離脱しやすいか」を定量化する。
-- 使用テクニック: CTE(3段), TIMESTAMPDIFF, NULLIF, ROUND
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
),
cohort_counts AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END) AS m0,
        COUNT(DISTINCT CASE WHEN month_offset = 1 THEN customer_id END) AS m1,
        COUNT(DISTINCT CASE WHEN month_offset = 2 THEN customer_id END) AS m2,
        COUNT(DISTINCT CASE WHEN month_offset = 3 THEN customer_id END) AS m3,
        COUNT(DISTINCT CASE WHEN month_offset = 4 THEN customer_id END) AS m4,
        COUNT(DISTINCT CASE WHEN month_offset = 5 THEN customer_id END) AS m5,
        COUNT(DISTINCT CASE WHEN month_offset = 6 THEN customer_id END) AS m6
    FROM order_cohort
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    m0                                                        AS cohort_size,
    ROUND(m1 / NULLIF(m0, 0) * 100, 1)                       AS m1_pct,
    ROUND(m2 / NULLIF(m0, 0) * 100, 1)                       AS m2_pct,
    ROUND(m3 / NULLIF(m0, 0) * 100, 1)                       AS m3_pct,
    ROUND(m4 / NULLIF(m0, 0) * 100, 1)                       AS m4_pct,
    ROUND(m5 / NULLIF(m0, 0) * 100, 1)                       AS m5_pct,
    ROUND(m6 / NULLIF(m0, 0) * 100, 1)                       AS m6_pct
FROM cohort_counts
ORDER BY cohort_month;
