-- =====================================================
-- クエリ名: 採用リードタイム（Time-to-Hire）分析
-- ビジネス課題: 応募から採用決定までの所要日数を求人別に集計し、
--              採用プロセスの効率性を評価する。
--              リードタイムが長い求人は優秀な候補者の離脱リスクが高い。
-- 使用テクニック: DATEDIFF, 集計関数（AVG, MIN, MAX）
-- 対象テーブル: applications, jobs
-- 実行環境: MySQL 8.0+
-- =====================================================

-- 採用済み（hired_flag = 1）の応募に絞り、
-- 応募日〜採用日の差分を求人別に集計
SELECT
    j.job_id,
    j.job_title,
    COUNT(*) AS hired_count,
    ROUND(AVG(DATEDIFF(a.hired_at, a.applied_at)), 1) AS avg_time_to_hire_days,
    MIN(DATEDIFF(a.hired_at, a.applied_at))           AS min_time_to_hire_days,
    MAX(DATEDIFF(a.hired_at, a.applied_at))           AS max_time_to_hire_days
FROM applications a
JOIN jobs j ON a.job_id = j.job_id
WHERE a.hired_flag = 1
GROUP BY j.job_id, j.job_title
ORDER BY avg_time_to_hire_days;
