-- =====================================================
-- クエリ名: 月次MRR推移
-- ビジネス課題: 月ごとの総MRRと前月比を追跡し、
--              事業の成長トレンドを定量的に把握する。
-- 使用テクニック: CTE(2段), SUM() OVER (累積合計), LAG()
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH monthly_changes AS (
    SELECT
        DATE_FORMAT(month, '%Y-%m') AS ym,
        SUM(mrr)                    AS net_mrr_change
    FROM saas_mrr_history
    GROUP BY DATE_FORMAT(month, '%Y-%m')
),
cumulative AS (
    SELECT
        ym,
        net_mrr_change,
        SUM(net_mrr_change) OVER (ORDER BY ym) AS total_mrr
    FROM monthly_changes
)
SELECT
    ym,
    net_mrr_change,
    total_mrr,
    LAG(total_mrr) OVER (ORDER BY ym) AS prev_mrr,
    ROUND(
        (total_mrr - LAG(total_mrr) OVER (ORDER BY ym)) /
        NULLIF(LAG(total_mrr) OVER (ORDER BY ym), 0) * 100, 1
    ) AS mom_growth_pct
FROM cumulative
ORDER BY ym;
