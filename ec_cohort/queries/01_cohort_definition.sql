-- =====================================================
-- クエリ名: コホート定義（初回購買月の特定）
-- ビジネス課題: 各顧客が「いつ初めて購買したか」を特定し、
--              コホート分析の基盤となるグループ分けを行う。
-- 使用テクニック: MIN(), DATE_FORMAT
-- 実行環境: MySQL 8.0+
-- =====================================================

SELECT
    o.customer_id,
    c.customer_name,
    DATE_FORMAT(MIN(o.order_date), '%Y-%m') AS cohort_month,
    MIN(o.order_date)                       AS first_order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status IN ('paid', 'shipped')
GROUP BY o.customer_id, c.customer_name
ORDER BY cohort_month, o.customer_id;
