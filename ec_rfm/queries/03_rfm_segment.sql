-- =====================================================
-- クエリ名: RFMセグメント分類
-- ビジネス課題: RFMスコアの組み合わせから顧客を
--              「VIP」「優良」「休眠リスク」「新規」「離脱」等に自動分類し、
--              セグメントごとのマーケティング施策判断に活用する。
-- 使用テクニック: CTE(3段), NTILE, CASE 多分岐
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
        NTILE(5) OVER (ORDER BY recency DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)  AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)   AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT
        *,
        r_score + f_score + m_score AS rfm_total,
        CASE
            -- VIP: 最近も買い、頻度も金額も高い
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'VIP'
            -- 優良顧客: スコア合計が高い
            WHEN r_score + f_score + m_score >= 11
                THEN '優良顧客'
            -- 新規有望: 最近買ったが回数はまだ少ない
            WHEN r_score >= 4 AND f_score <= 2
                THEN '新規有望'
            -- 休眠リスク: 以前は買っていたが最近来ていない
            WHEN r_score <= 2 AND f_score >= 3
                THEN '休眠リスク'
            -- 離脱: 長期間購買なし & 低頻度
            WHEN r_score <= 2 AND f_score <= 2
                THEN '離脱'
            ELSE 'その他'
        END AS segment
    FROM scored
)
SELECT
    seg.customer_id,
    c.customer_name,
    seg.r_score,
    seg.f_score,
    seg.m_score,
    seg.rfm_total,
    seg.segment
FROM segmented seg
JOIN customers c ON seg.customer_id = c.customer_id
ORDER BY seg.rfm_total DESC, seg.monetary DESC;
