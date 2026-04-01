-- =====================================================
-- クエリ名: 月次売上推移・前月比分析
-- ビジネス課題: 売上の月次トレンドと前月からの増減率を把握し、
--              異常値の早期検知や施策効果の評価に活用する。
-- 使用テクニック: CTE, LAG() ウィンドウ関数, DATE_FORMAT, NULLIF
-- 対象テーブル: orders, order_items
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 月ごとの売上合計を算出（未決済・キャンセルは除外）
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS ym,
        SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid','shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
-- Step 2: LAG() で前月の売上を取得し、前月比（%）を計算
SELECT
    ym,
    revenue,
    LAG(revenue) OVER (ORDER BY ym) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY ym)) /
        NULLIF(LAG(revenue) OVER (ORDER BY ym), 0) * 100,
        1
    ) AS mom_change_pct
FROM monthly_sales
ORDER BY ym;
