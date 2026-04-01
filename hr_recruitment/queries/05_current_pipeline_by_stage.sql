-- =====================================================
-- クエリ名: 現在のパイプライン（最新ステージ別件数）
-- ビジネス課題: 各候補者の「現在いるステージ」を特定し、求人ごとの
--              滞留状況を可視化する。面接待ちが多い場合は面接官の
--              アサイン強化など、即座のアクションにつなげる。
-- 使用テクニック: ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ... DESC),
--              CTE による最新レコード抽出パターン
-- 対象テーブル: application_stages, applications, jobs
-- 実行環境: MySQL 8.0+
-- =====================================================

-- Step 1: 各応募の最新ステージを ROW_NUMBER() で特定
WITH latest_stage AS (
    SELECT
        s.application_id,
        s.stage_name,
        s.stage_entered_at,
        ROW_NUMBER() OVER (
            PARTITION BY s.application_id
            ORDER BY s.stage_entered_at DESC
        ) AS rn
    FROM application_stages s
)
-- Step 2: 最新ステージ（rn = 1）のみ抽出し、求人×ステージ別に件数を集計
SELECT
    j.job_id,
    j.job_title,
    ls.stage_name,
    COUNT(*) AS count_in_stage
FROM latest_stage ls
JOIN applications a ON ls.application_id = a.application_id
JOIN jobs j        ON a.job_id = j.job_id
WHERE ls.rn = 1
GROUP BY j.job_id, j.job_title, ls.stage_name
ORDER BY j.job_id, ls.stage_name;
