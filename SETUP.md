# 環境構築・実行手順

## 前提条件

- **MySQL 8.0 以上** がインストールされていること
- `mysql` コマンドラインクライアント、または MySQL Workbench 等のGUIツールが利用可能であること

---

## 手順

### 1. データベースの作成

```sql
CREATE DATABASE sql_portfolio DEFAULT CHARACTER SET utf8mb4;
USE sql_portfolio;
```

### 2. テーブル作成

```sql
-- EC売上分析（ec_sales / ec_rfm / ec_cohort で共用）
SOURCE ec_sales/schema/create_tables.sql;

-- 採用管理分析
SOURCE hr_recruitment/schema/create_tables.sql;

-- SaaSメトリクス分析
SOURCE saas_metrics/schema/create_tables.sql;
```

### 3. サンプルデータの投入

#### 方法A: LOAD DATA（コマンドライン）

```sql
-- EC売上分析
LOAD DATA LOCAL INFILE 'ec_sales/data/categories.csv'
  INTO TABLE categories
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'ec_sales/data/customers.csv'
  INTO TABLE customers
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'ec_sales/data/products.csv'
  INTO TABLE products
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'ec_sales/data/orders.csv'
  INTO TABLE orders
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'ec_sales/data/order_items.csv'
  INTO TABLE order_items
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

-- 採用管理分析
LOAD DATA LOCAL INFILE 'hr_recruitment/data/candidates.csv'
  INTO TABLE candidates
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'hr_recruitment/data/jobs.csv'
  INTO TABLE jobs
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'hr_recruitment/data/sources.csv'
  INTO TABLE sources
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'hr_recruitment/data/applications.csv'
  INTO TABLE applications
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'hr_recruitment/data/application_stages.csv'
  INTO TABLE application_stages
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS;
```

> **注意:** `LOAD DATA LOCAL INFILE` を使用するには、MySQL接続時に `--local-infile=1` オプションが必要な場合があります。
>
> ```bash
> mysql --local-infile=1 -u root -p sql_portfolio
> ```

#### 方法B: GUIツール（MySQL Workbench 等）

各GUIツールのCSVインポート機能を使用して、`data/` 内のCSVファイルを対応するテーブルに取り込んでください。

**投入順序（外部キー制約のため順序を守ること）:**

EC売上分析:
1. `categories.csv` → categories
2. `customers.csv` → customers
3. `products.csv` → products
4. `orders.csv` → orders
5. `order_items.csv` → order_items

採用管理分析:
1. `candidates.csv` → candidates
2. `jobs.csv` → jobs
3. `sources.csv` → sources
4. `applications.csv` → applications
5. `application_stages.csv` → application_stages

SaaSメトリクス分析:
1. `saas_plans.csv` → saas_plans
2. `saas_customers.csv` → saas_customers
3. `saas_mrr_history.csv` → saas_mrr_history

### 4. 分析クエリの実行

```sql
-- 例: EC売上の月次推移を確認
SOURCE ec_sales/queries/01_monthly_sales.sql;

-- 例: RFMセグメント分類
SOURCE ec_rfm/queries/03_rfm_segment.sql;

-- 例: コホートリテンション率
SOURCE ec_cohort/queries/04_cohort_retention_rate.sql;

-- 例: 採用ファネルの転換率を確認
SOURCE hr_recruitment/queries/02_job_funnel_conversion.sql;

-- 例: SaaS月次MRR推移
SOURCE saas_metrics/queries/01_monthly_mrr.sql;
```

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| `ERROR 3948: Loading local data is disabled` | ローカルファイル読み込みが無効 | `SET GLOBAL local_infile = 1;` を実行、または `--local-infile=1` で接続 |
| `ERROR 1452: Cannot add or update a child row` | 外部キー制約違反 | 上記の投入順序を守ってデータを再投入 |
| `ERROR 1366: Incorrect string value` | 文字コードの不一致 | データベースが `utf8mb4` で作成されているか確認 |
