-- =====================================================
-- クエリ名: カテゴリ別売上ランキング
-- ビジネス課題: 売上貢献度の高い商品カテゴリを特定し、
--              仕入れやプロモーション戦略の優先順位付けに活用する。
-- 使用テクニック: 4テーブルJOIN, GROUP BY, ORDER BY DESC, LIMIT
-- 対象テーブル: order_items, orders, products, categories
-- 実行環境: MySQL 8.0+
-- =====================================================

-- 注文明細 → 注文 → 商品 → カテゴリ の4テーブルを結合し、
-- カテゴリ単位で売上を集計してランキング化
SELECT
    c.category_name,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders    o ON oi.order_id   = o.order_id
JOIN products  p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.status IN ('paid','shipped')
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC
LIMIT 10;
