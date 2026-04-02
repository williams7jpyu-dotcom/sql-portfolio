-- =====================================================
-- クエリ名: MRR変動の内訳（新規/拡張/縮小/解約）
-- ビジネス課題: MRRの増減要因を分類し、
--              「新規獲得で伸びているのか、解約で減っているのか」を把握する。
-- 使用テクニック: 条件付き集計(CASE + SUM), GROUP BY
-- 実行環境: MySQL 8.0+
-- =====================================================

SELECT
    DATE_FORMAT(month, '%Y-%m') AS ym,
    SUM(CASE WHEN change_type = 'new'          THEN mrr ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN change_type = 'expansion'    THEN mrr ELSE 0 END) AS expansion_mrr,
    SUM(CASE WHEN change_type = 'contraction'  THEN mrr ELSE 0 END) AS contraction_mrr,
    SUM(CASE WHEN change_type = 'churn'        THEN mrr ELSE 0 END) AS churn_mrr,
    SUM(CASE WHEN change_type = 'reactivation' THEN mrr ELSE 0 END) AS reactivation_mrr,
    SUM(mrr)                                                         AS net_change
FROM saas_mrr_history
GROUP BY DATE_FORMAT(month, '%Y-%m')
ORDER BY ym;
