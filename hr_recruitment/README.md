# 採用管理・ファネル分析

## 概要

架空の採用管理システムを想定し、応募〜選考〜内定〜採用の各ステージデータから
採用プロセスの効率性と改善ポイントを可視化するプロジェクトです。

「どの選考ステージがボトルネックか？」「採用までに何日かかっているか？」「どの媒体が費用対効果が高いか？」など、
人事・採用チームが日常的に直面する課題にSQLで回答します。

---

## 作成意図

採用・HR領域のデータ分析は、IT企業だけでなく全業種で注目されているテーマです。
このプロジェクトを選んだ理由は、**EC売上分析とは異なるドメインの知識と、別の技術パターンを実証するため**です。

具体的には以下の点を意識して設計しました。

**ビジネス観点：**
- 採用は「どこに投資するか」（媒体選定）と「どこを改善するか」（ボトルネック特定）の2軸が重要であり、SQLで両方を定量化できることを示した
- 「Time-to-Hire（採用リードタイム）」は採用チームが最も気にする指標の一つで、長期化が優秀な候補者の辞退リスクに直結する現実的な課題を扱った

**技術観点：**
- `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` による「各グループの最新レコードを1件抽出」は、採用ステージだけでなく最新ログ取得・最新価格取得など**あらゆるシーンで使う定番パターン**として示した
- `unique key (application_id, stage_name)` というスキーマ設計でデータ整合性を担保する設計力も含めた

---

## ER図

```
candidates               applications                  application_stages
+------------------+     +--------------------+        +--------------------+
| candidate_id     |<─┐  | application_id     |<──────| application_id(FK) |
| full_name        |  └──| candidate_id (FK)  |       | stage_id           |
| email            |     | job_id (FK)      ──|──┐    | stage_name         |
| phone            |     | source_id (FK)   ──|──|─┐  | stage_entered_at   |
| gender           |     | applied_at         |  | |  | stage_left_at      |
| age              |     | current_status     |  | |  | result             |
| current_city     |     | hired_flag         |  | |  +--------------------+
| current_role     |     | hired_at           |  | |
| experience_years |     | rejected_at        |  | |  sources
| created_at       |     +--------------------+  | |  +------------------+
+------------------+                              | └──| source_id        |
                          jobs                    |    | source_name      |
                          +------------------+    |    | source_type      |
                          | job_id           |<───┘    +------------------+
                          | job_title        |
                          | department       |
                          | employment_type  |
                          | location         |
                          | posted_date      |
                          | closed_date      |
                          | headcount        |
                          +------------------+
```

**テーブル構成:** 5テーブル / 外部キー4本 / インデックス3本 / ユニークキー1本

---

## 分析クエリ一覧

### 01. 求人別ファネル件数

**ファイル:** [`queries/01_job_funnel_counts.sql`](./queries/01_job_funnel_counts.sql)

**ビジネス課題:** 求人ごとに応募〜面接〜内定〜採用の到達人数を一覧化し、選考の進捗状況を俯瞰する。

**使用技術:** `COUNT(DISTINCT CASE WHEN ...)` による条件付き集計, `LEFT JOIN`

**期待出力:**

| job_id | job_title | applied_count | interview_count | offer_count | hired_count |
|--------|-----------|---------------|-----------------|-------------|-------------|
| 3 | システムエンジニア | 2 | 1 | 0 | 0 |
| 1 | 内勤営業 | 1 | 1 | 1 | 1 |
| 2 | カスタマーサポート | 1 | 0 | 0 | 0 |

---

### 02. ファネルコンバージョン率

**ファイル:** [`queries/02_job_funnel_conversion.sql`](./queries/02_job_funnel_conversion.sql)

**ビジネス課題:** 各選考ステージ間の通過率を算出し、歩留まりが悪いステージ（ボトルネック）を特定する。

**使用技術:** CTE（ファネル件数を先に算出）, `NULLIF`によるゼロ除算防止, 比率計算

**期待出力:**

| job_id | job_title | applied | interview | offer | hired | app_to_interview_pct | interview_to_offer_pct | offer_to_hire_pct | app_to_hire_pct |
|--------|-----------|---------|-----------|-------|-------|---------------------|----------------------|------------------|----------------|
| 1 | 内勤営業 | 1 | 1 | 1 | 1 | 100.0 | 100.0 | 100.0 | 100.00 |
| 3 | システムエンジニア | 2 | 1 | 0 | 0 | 50.0 | 0.0 | NULL | 0.00 |
| 2 | カスタマーサポート | 1 | 0 | 0 | 0 | 0.0 | NULL | NULL | 0.00 |

---

### 03. 採用リードタイム（Time-to-Hire）

**ファイル:** [`queries/03_time_to_hire.sql`](./queries/03_time_to_hire.sql)

**ビジネス課題:** 応募から採用決定までの所要日数を求人別に集計し、採用プロセスの効率性を評価する。長すぎるリードタイムは優秀な候補者の離脱リスクを高める。

**使用技術:** `DATEDIFF`, 集計関数（`AVG`, `MIN`, `MAX`）

**期待出力:**

| job_id | job_title | hired_count | avg_time_to_hire_days | min_time_to_hire_days | max_time_to_hire_days |
|--------|-----------|-------------|-----------------------|-----------------------|-----------------------|
| 1 | 内勤営業 | 1 | 19.0 | 19 | 19 |

---

### 04. 媒体別採用パフォーマンス

**ファイル:** [`queries/04_source_performance.sql`](./queries/04_source_performance.sql)

**ビジネス課題:** 求人媒体（求人サイト・リファラル・エージェント等）ごとの応募数・採用数・転換率を比較し、採用チャネルへの投資判断に活用する。

**使用技術:** `LEFT JOIN`, `CASE`式による条件付き集計, `NULLIF`

**期待出力:**

| source_id | source_name | source_type | applications | hires | app_to_hire_pct |
|-----------|-------------|-------------|-------------|-------|-----------------|
| 1 | JobBoard A | job_board | 2 | 1 | 50.00 |
| 2 | Referral | referral | 1 | 0 | 0.00 |
| 3 | Company Website | direct | 1 | 0 | 0.00 |

---

### 05. 現在のパイプライン（最新ステージ別件数）

**ファイル:** [`queries/05_current_pipeline_by_stage.sql`](./queries/05_current_pipeline_by_stage.sql)

**ビジネス課題:** 各候補者の「現在いるステージ」を特定し、求人ごとの滞留状況を可視化する。面接待ちが多い場合は面接官のアサイン強化など、即座のアクションにつなげる。

**使用技術:** `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ... DESC)` で最新ステージを特定, CTE

**期待出力:**

| job_id | job_title | stage_name | count_in_stage |
|--------|-----------|------------|----------------|
| 1 | 内勤営業 | hired | 1 |
| 2 | カスタマーサポート | rejected | 1 |
| 3 | システムエンジニア | applied | 1 |
| 3 | システムエンジニア | interview | 1 |

---

## テーブル定義

**スキーマファイル:** [`schema/create_tables.sql`](./schema/create_tables.sql)

| テーブル | 主な役割 | 行数 |
|---------|---------|------|
| candidates | 候補者マスタ（氏名・経験年数・現職） | 20 |
| jobs | 求人マスタ（職種・部署・雇用形態・募集人数） | 6 |
| sources | 媒体マスタ（求人サイト・リファラル等） | 5 |
| applications | 応募トランザクション（応募日・ステータス・採用日） | 25 |
| application_stages | 選考ステージ履歴（各ステージの入退出日・結果） | 69 |

---

## データ仕様

- **期間:** 2024年1月〜8月
- **求人:** 内勤営業 / カスタマーサポート / システムエンジニア（計3ポジション）
- **媒体:** JobBoard A / Referral / Company Website（計3チャネル）
- **選考ステージ:** applied → screening → interview → offer → hired（または rejected）
- **分析対象:** `hired_flag = 1` で採用済みを抽出、`application_stages` で詳細な選考履歴を追跡
