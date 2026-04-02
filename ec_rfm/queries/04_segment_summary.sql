-- =====================================================
-- クエリ名: セグメント別集計レポート
-- ビジネス課題: 各セグメントの人数・平均LTV・平均購買間隔を集計し、
--              セグメントごとの特性を定量的に把握する。
-- 使用テクニック: CTE(4段), NTILE, CASE, GROUP BY 集計
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH customer_rfm AS (
    SELECT
        o.customer_id,
        DATEDIFF(CURDATE(), MAX(o.order_date))  AS recency,
        COUNT(DISTINCT o.order_id)              AS frequency,
        SUM(oi.quantity * oi.unit_price)         AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid', 'shipped')
    GROUP BY o.customer_id
),
scored AS (
    SELECT
        customer_id, recency, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)  AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)   AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
            WHEN r_score + f_score + m_score >= 11             THEN '優良顧客'
            WHEN r_score >= 4 AND f_score <= 2                  THEN '新規有望'
            WHEN r_score <= 2 AND f_score >= 3                  THEN '休眠リスク'
            WHEN r_score <= 2 AND f_score <= 2                  THEN '離脱'
            ELSE 'その他'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                              AS customer_count,
    ROUND(AVG(monetary), 0)               AS avg_ltv,
    ROUND(AVG(frequency), 1)              AS avg_frequency,
    ROUND(AVG(recency), 0)                AS avg_recency_days,
    ROUND(AVG(monetary / NULLIF(frequency, 0)), 0) AS avg_order_value
FROM segmented
GROUP BY segment
ORDER BY avg_ltv DESC;
