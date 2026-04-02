-- =====================================================
-- クエリ名: 経過月別 平均リテンション率サマリ
-- ビジネス課題: 全コホートを横断して「N ヶ月後の平均残存率」を算出し、
--              サービス全体のリテンション傾向を把握する。
-- 使用テクニック: CTE(3段), AVG, NULLIF, TIMESTAMPDIFF
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status IN ('paid', 'shipped')
    GROUP BY customer_id
),
order_cohort AS (
    SELECT
        fp.customer_id,
        TIMESTAMPDIFF(MONTH, fp.first_order_date, o.order_date) AS month_offset
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.status IN ('paid', 'shipped')
),
cohort_stats AS (
    -- 各顧客が month_offset = N に購買したかどうか（0/1）
    SELECT
        oc.customer_id,
        oc.month_offset,
        1 AS active
    FROM order_cohort oc
    WHERE oc.month_offset > 0
    GROUP BY oc.customer_id, oc.month_offset
)
SELECT
    cs.month_offset                                AS months_after_first,
    COUNT(DISTINCT cs.customer_id)                 AS active_customers,
    (SELECT COUNT(DISTINCT customer_id)
     FROM first_purchase)                          AS total_customers,
    ROUND(
        COUNT(DISTINCT cs.customer_id) /
        NULLIF((SELECT COUNT(DISTINCT customer_id) FROM first_purchase), 0)
        * 100, 1
    )                                              AS avg_retention_pct
FROM cohort_stats cs
GROUP BY cs.month_offset
ORDER BY cs.month_offset;
