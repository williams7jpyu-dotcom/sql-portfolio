-- =====================================================
-- クエリ名: 求人別ファネル件数
-- ビジネス課題: 求人ごとに応募〜面接〜内定〜採用の到達人数を一覧化し、
--              選考の進捗状況を俯瞰する。
-- 使用テクニック: COUNT(DISTINCT CASE WHEN ...) による条件付き集計, LEFT JOIN
-- 対象テーブル: jobs, applications, application_stages
-- 実行環境: MySQL 8.0+
-- =====================================================

-- LEFT JOIN で全応募を保持しつつ、CASE式で各ステージの到達者を個別カウント
SELECT
    j.job_id,
    j.job_title,
    COUNT(DISTINCT a.application_id) AS applied_count,
    COUNT(DISTINCT CASE WHEN s.stage_name = 'interview' THEN s.application_id END) AS interview_count,
    COUNT(DISTINCT CASE WHEN s.stage_name = 'offer'     THEN s.application_id END) AS offer_count,
    COUNT(DISTINCT CASE WHEN s.stage_name = 'hired'     THEN s.application_id END) AS hired_count
FROM jobs j
JOIN applications a
  ON j.job_id = a.job_id
LEFT JOIN application_stages s
  ON a.application_id = s.application_id
GROUP BY j.job_id, j.job_title
ORDER BY applied_count DESC;
