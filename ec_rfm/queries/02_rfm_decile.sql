-- =====================================================
-- クエリ名: RFMスコアのデシル化（5段階スコアリング）
-- ビジネス課題: R/F/M それぞれを5段階にスコアリングし、
--              顧客を定量的に比較可能な指標へ変換する。
-- 使用テクニック: CTE(多段), NTILE(5) ウィンドウ関数
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
        customer_id,
        recency,
        frequency,
        monetary,
        -- Recency は小さいほうが良いので DESC でスコア付け
        NTILE(5) OVER (ORDER BY recency DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)  AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)   AS m_score
    FROM customer_rfm
)
SELECT
    s.customer_id,
    c.customer_name,
    s.recency,
    s.frequency,
    s.monetary,
    s.r_score,
    s.f_score,
    s.m_score,
    s.r_score + s.f_score + s.m_score AS rfm_total
FROM scored s
JOIN customers c ON s.customer_id = c.customer_id
ORDER BY rfm_total DESC, s.monetary DESC;
