-- =====================================================
-- クエリ名: 媒体別採用パフォーマンス
-- ビジネス課題: 求人媒体（求人サイト・リファラル・自社サイト等）ごとの
--              応募数・採用数・転換率を比較し、
--              採用チャネルへの投資判断（ROI）に活用する。
-- 使用テクニック: LEFT JOIN, CASE式による条件付き集計, NULLIF
-- 対象テーブル: applications, sources
-- 実行環境: MySQL 8.0+
-- =====================================================

-- 媒体ごとに応募総数と採用数を集計し、転換率を算出
SELECT
    s.source_id,
    s.source_name,
    s.source_type,
    COUNT(*) AS applications,
    SUM(CASE WHEN a.hired_flag = 1 THEN 1 ELSE 0 END) AS hires,
    ROUND(SUM(CASE WHEN a.hired_flag = 1 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(*), 0) * 100, 2) AS app_to_hire_pct
FROM applications a
LEFT JOIN sources s ON a.source_id = s.source_id
GROUP BY s.source_id, s.source_name, s.source_type
ORDER BY app_to_hire_pct DESC;
