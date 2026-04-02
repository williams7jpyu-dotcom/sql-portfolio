-- =====================================================
-- クエリ名: 月次チャーンレート（顧客解約率）
-- ビジネス課題: 月ごとの解約顧客数と前月末アクティブ顧客数から
--              チャーンレートを算出し、顧客維持の健全性を評価する。
-- 使用テクニック: CTE, サブクエリ, LEAD(), DATE_FORMAT
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH monthly_signups AS (
    -- 各月末時点での累計契約数
    SELECT
        DATE_FORMAT(signup_date, '%Y-%m') AS ym,
        COUNT(*)                           AS new_signups
    FROM saas_customers
    GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
),
monthly_churns AS (
    SELECT
        DATE_FORMAT(churned_date, '%Y-%m') AS ym,
        COUNT(*)                            AS churned_count
    FROM saas_customers
    WHERE churned_date IS NOT NULL
    GROUP BY DATE_FORMAT(churned_date, '%Y-%m')
),
-- 各月の顧客数を累積計算
months AS (
    SELECT DISTINCT DATE_FORMAT(month, '%Y-%m') AS ym
    FROM saas_mrr_history
),
customer_counts AS (
    SELECT
        m.ym,
        (SELECT COUNT(*) FROM saas_customers
         WHERE DATE_FORMAT(signup_date, '%Y-%m') <= m.ym
           AND (churned_date IS NULL OR DATE_FORMAT(churned_date, '%Y-%m') > m.ym)
        ) AS active_customers_eom,
        COALESCE(mc.churned_count, 0) AS churned_in_month
    FROM months m
    LEFT JOIN monthly_churns mc ON m.ym = mc.ym
)
SELECT
    ym,
    active_customers_eom,
    churned_in_month,
    ROUND(
        churned_in_month /
        NULLIF(active_customers_eom + churned_in_month, 0) * 100, 2
    ) AS churn_rate_pct
FROM customer_counts
ORDER BY ym;
