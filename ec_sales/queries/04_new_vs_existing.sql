-- =====================================================
-- クエリ名: 新規顧客 vs 既存顧客の月次売上比較
-- ビジネス課題: 月ごとの売上が新規獲得とリピートのどちらに依存しているかを
--              把握し、マーケティング予算の配分判断（獲得 vs 維持）に用いる。
-- 使用テクニック: CTE（初回注文日を特定）, CASE式による分類, DATE関数
-- 対象テーブル: orders, order_items
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 顧客ごとの初回注文日を特定
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status IN ('paid','shipped')
    GROUP BY customer_id
),
-- Step 2: 各注文を「初回注文日と同日 → new」「それ以降 → existing」に分類
order_with_flag AS (
    SELECT
        o.*,
        CASE
            WHEN DATE(o.order_date) = DATE(f.first_order_date)
                THEN 'new'
            ELSE 'existing'
        END AS customer_type
    FROM orders o
    JOIN first_orders f ON o.customer_id = f.customer_id
    WHERE o.status IN ('paid','shipped')
)
-- Step 3: 月×顧客タイプ別に売上を集計
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS ym,
    customer_type,
    SUM(oi.quantity * oi.unit_price)   AS revenue
FROM order_with_flag o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), customer_type
ORDER BY ym, customer_type;
