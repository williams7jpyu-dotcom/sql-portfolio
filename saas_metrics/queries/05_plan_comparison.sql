-- =====================================================
-- クエリ名: プラン別ARPU・解約率比較
-- ビジネス課題: プランタイプごとの平均MRR・顧客数・解約率を比較し、
--              どのプランが収益貢献度が高く、どれが解約リスクが高いかを把握する。
-- 使用テクニック: LEFT JOIN, GROUP BY, 条件付き集計
-- 実行環境: MySQL 8.0+
-- =====================================================

SELECT
    p.plan_id,
    p.plan_name,
    p.monthly_price,
    COUNT(sc.customer_id)                                         AS total_customers,
    SUM(CASE WHEN sc.is_active = 1 THEN 1 ELSE 0 END)            AS active_customers,
    SUM(CASE WHEN sc.churned_date IS NOT NULL THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        SUM(CASE WHEN sc.churned_date IS NOT NULL THEN 1 ELSE 0 END) /
        NULLIF(COUNT(sc.customer_id), 0) * 100, 1
    )                                                              AS churn_rate_pct,
    ROUND(
        SUM(CASE WHEN sc.is_active = 1 THEN p.monthly_price ELSE 0 END), 0
    )                                                              AS current_total_mrr,
    ROUND(
        AVG(CASE WHEN sc.is_active = 1 THEN p.monthly_price END), 0
    )                                                              AS arpu
FROM saas_plans p
LEFT JOIN saas_customers sc ON p.plan_id = sc.plan_id
GROUP BY p.plan_id, p.plan_name, p.monthly_price
ORDER BY p.monthly_price DESC;
