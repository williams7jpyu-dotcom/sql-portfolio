-- =====================================================
-- クエリ名: 顧客LTV推計
-- ビジネス課題: ARPU（顧客あたり平均月次収益）と
--              月次チャーンレートから理論LTVを推計し、
--              顧客獲得コスト(CAC)の上限判断に活用する。
-- 使用テクニック: サブクエリ, NULLIF, 集計関数
-- 実行環境: MySQL 8.0+
-- =====================================================

WITH arpu AS (
    -- 直近月のARPU（アクティブ顧客のみ）
    SELECT
        ROUND(AVG(p.monthly_price), 0) AS avg_mrr_per_customer
    FROM saas_customers sc
    JOIN saas_plans p ON sc.plan_id = p.plan_id
    WHERE sc.is_active = 1
),
churn AS (
    -- 全期間の月次平均チャーンレート
    SELECT
        ROUND(
            COUNT(CASE WHEN churned_date IS NOT NULL THEN 1 END) /
            NULLIF(COUNT(*), 0) /
            -- 平均在籍月数で割って月次レートに変換
            NULLIF(
                TIMESTAMPDIFF(MONTH,
                    (SELECT MIN(signup_date) FROM saas_customers),
                    CURDATE()
                ), 0
            ) * 100, 2
        ) AS monthly_churn_rate_pct
    FROM saas_customers
)
SELECT
    a.avg_mrr_per_customer              AS arpu,
    c.monthly_churn_rate_pct            AS monthly_churn_pct,
    CASE
        WHEN c.monthly_churn_rate_pct > 0 THEN
            ROUND(a.avg_mrr_per_customer / (c.monthly_churn_rate_pct / 100), 0)
        ELSE NULL
    END                                 AS estimated_ltv,
    CASE
        WHEN c.monthly_churn_rate_pct > 0 THEN
            ROUND(1 / (c.monthly_churn_rate_pct / 100), 1)
        ELSE NULL
    END                                 AS avg_lifetime_months
FROM arpu a
CROSS JOIN churn c;
