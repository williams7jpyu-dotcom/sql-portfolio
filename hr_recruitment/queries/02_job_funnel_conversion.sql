-- =====================================================
-- クエリ名: ファネルコンバージョン率
-- ビジネス課題: 各選考ステージ間の通過率を算出し、
--              歩留まりが悪いステージ（ボトルネック）を特定する。
-- 使用テクニック: CTE, NULLIF によるゼロ除算防止, 比率計算
-- 対象テーブル: jobs, applications, application_stages
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 求人ごとの各ステージ到達者数を集計
WITH funnel AS (
    SELECT
        j.job_id,
        j.job_title,
        COUNT(DISTINCT a.application_id) AS applied_count,
        COUNT(DISTINCT CASE WHEN s.stage_name = 'interview' THEN s.application_id END) AS interview_count,
        COUNT(DISTINCT CASE WHEN s.stage_name = 'offer'     THEN s.application_id END) AS offer_count,
        COUNT(DISTINCT CASE WHEN s.stage_name = 'hired'     THEN s.application_id END) AS hired_count
    FROM jobs j
    JOIN applications a ON j.job_id = a.job_id
    LEFT JOIN application_stages s ON a.application_id = s.application_id
    GROUP BY j.job_id, j.job_title
)
-- Step 2: ステージ間の転換率を算出（NULLIF でゼロ除算を防止）
SELECT
    job_id,
    job_title,
    applied_count,
    interview_count,
    offer_count,
    hired_count,
    ROUND(interview_count / NULLIF(applied_count, 0) * 100, 1) AS app_to_interview_pct,
    ROUND(offer_count     / NULLIF(interview_count, 0) * 100, 1) AS interview_to_offer_pct,
    ROUND(hired_count     / NULLIF(offer_count, 0) * 100, 1) AS offer_to_hire_pct,
    ROUND(hired_count     / NULLIF(applied_count, 0) * 100, 2) AS app_to_hire_pct
FROM funnel
ORDER BY app_to_hire_pct DESC;
