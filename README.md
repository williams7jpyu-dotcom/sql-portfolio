# SQL Portfolio — データ分析クエリ集

実務を想定したビジネスデータに対し、SQLで分析を行うポートフォリオです。
スキーマ設計からサンプルデータ作成、分析クエリの実装までを一貫して行っています。

---

## プロジェクト一覧

| # | プロジェクト | テーマ | 概要 |
|---|------------|------|------|
| 1 | [EC売上・顧客分析](./ec_sales/) | EC / マーケティング | 月次売上推移、カテゴリ別ランキング、顧客LTV、新規/既存比較、売上集中度分析 |
| 2 | [採用管理・ファネル分析](./hr_recruitment/) | HR / 採用 | 採用ファネル可視化、コンバージョン率、採用リードタイム、媒体別効果、パイプライン分析 |
| 3 | [RFM顧客セグメンテーション](./ec_rfm/) | CRM / マーケティング | R（最終購買日）・F（購買頻度）・M（購買金額）の3軸で顧客をスコアリング・セグメント分類 |
| 4 | [コホート・リテンション分析](./ec_cohort/) | グロース / 継続率 | 初回購買月ごとに顧客をグループ化し、月次の継続率（リテンション）を追跡 |
| 5 | [SaaSビジネスメトリクス](./saas_metrics/) | SaaS / サブスクリプション | MRR推移・変動内訳・チャーンレート・LTV推計・プラン別比較 |

---

## 使用技術・SQLスキル

### テーブル設計

- 正規化（第3正規形）に基づくリレーショナル設計
- 外部キー制約によるデータ整合性の保証
- パフォーマンスを意識したインデックス設計（検索頻度の高いカラムに付与）
- ENUM型による値の制約

### 分析クエリ

| 技術 | 使用箇所 |
|------|---------|
| ウィンドウ関数（LAG, NTILE, ROW_NUMBER, SUM OVER） | 前月比算出、デシル分析、累積MRR計算 |
| CTE（共通テーブル式・多段） | 複数ステップの分析ロジックを段階的に構築 |
| 条件付き集計（CASE + 集計関数） | ファネル集計、MRR変動内訳、リテンションテーブル |
| 複数テーブルJOIN（INNER / LEFT / CROSS） | 4テーブル結合、媒体×採用の横断集計 |
| 日付関数（DATE_FORMAT, DATEDIFF, TIMESTAMPDIFF） | 月次集計、リードタイム算出、コホート経過月 |
| NULL安全な除算（NULLIF） | ゼロ除算を防止した比率計算 |
| DENSE_RANK / NTILE（多軸適用） | RFMスコアリング、顧客ランキング |
| サブクエリ（スカラー / 相関） | チャーンレート算出、LTV推計 |

---

## ディレクトリ構成

```
sql_portfolio/
│
├── ec_sales/                          EC売上・顧客分析（5クエリ）
│   ├── schema/create_tables.sql
│   ├── data/
│   └── queries/
│
├── hr_recruitment/                    採用管理・ファネル分析（5クエリ）
│   ├── schema/create_tables.sql
│   ├── data/
│   └── queries/
│
├── ec_rfm/                            RFM顧客セグメンテーション（5クエリ）
│   └── queries/                       ※ ec_salesのデータを参照
│
├── ec_cohort/                         コホート・リテンション分析（5クエリ）
│   └── queries/                       ※ ec_salesのデータを参照
│
├── saas_metrics/                      SaaSビジネスメトリクス（5クエリ）
│   ├── schema/create_tables.sql
│   ├── data/
│   └── queries/
│
├── README.md                          本ファイル
└── SETUP.md                           環境構築・実行手順
```

---

## 環境・実行方法

- **RDBMS:** MySQL 8.0 以上
- **詳細手順:** [SETUP.md](./SETUP.md) を参照

```sql
-- 1. テーブル作成
SOURCE ec_sales/schema/create_tables.sql;

-- 2. データ投入（LOAD DATA または各種GUIツールでCSVをインポート）

-- 3. 分析クエリの実行
SOURCE ec_sales/queries/01_monthly_sales.sql;
```
