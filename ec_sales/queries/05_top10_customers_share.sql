-- =====================================================
-- クエリ名: 売上トップ10%顧客の集中度分析（パレート分析）
-- ビジネス課題: 売上上位顧客への依存度を定量化し、顧客基盤の
--              リスク評価や優良顧客向け施策の費用対効果を検討する。
-- 使用テクニック: CTE（3段階）, NTILE()ウィンドウ関数, 条件付き集計
-- 対象テーブル: orders, order_items
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 顧客ごとの累計売上を算出
WITH customer_ltv AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('paid','shipped')
    GROUP BY o.customer_id
),
-- Step 2: NTILE(10) で顧客を売上順に10分割（デシル）
ranked AS (
    SELECT
        customer_id,
        revenue,
        NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM customer_ltv
),
-- Step 3: 上位10%（decile = 1）の売上合計と全体売上を集計
agg AS (
    SELECT
        SUM(revenue) AS total_revenue,
        SUM(CASE WHEN decile = 1 THEN revenue ELSE 0 END) AS top10_revenue
    FROM ranked
)
SELECT
    total_revenue,
    top10_revenue,
    ROUND(top10_revenue / total_revenue * 100, 1) AS top10_share_pct
FROM agg;
