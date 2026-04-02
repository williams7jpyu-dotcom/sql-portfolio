# SaaSビジネスメトリクス分析

## プロジェクト概要

架空のSaaS（サブスクリプション型サービス）の契約・収益データを用いて、
MRR（月次経常収益）・チャーンレート（解約率）・LTV（顧客生涯価値）を分析します。

SaaS企業の経営判断やグロース戦略に不可欠な指標を網羅しています。

## 作成意図

SaaSビジネスの指標（MRR・チャーンレート・LTV）は、スタートアップから上場企業まで投資家・経営層が最も注目する数値であり、この領域のデータ分析スキルは市場価値が高いテーマです。
このプロジェクトを選んだ理由は、**EC・HR・RFM・コホートとは異なるサブスクリプション型ビジネスのドメイン知識と技術パターンを実証するため**です。

**ビジネス観点：**
- MRRの「増減内訳（新規・拡張・縮小・解約・再契約）」を分解することで、成長の質を評価できる点を示した。単なる売上合計ではなく、「なぜ増えたか／減ったか」まで掘り下げる分析視点を意識した
- LTV＝ARPU÷チャーンレートという推計式を用いることで、CACとの比較による投資判断が可能になる実践的な課題を扱った

**技術観点：**
- 月次チャーンレートの算出では「前月末時点のアクティブ顧客数を分母にする」必要があるため、サブクエリで前月のスナップショットを参照する相関サブクエリパターンを実装した
- `CROSS JOIN` によるARPU×チャーンレートの組み合わせ計算は、集計軸が異なる2つの値を掛け合わせる汎用的なパターンとして示した

---

## ER図

```
saas_plans ──┐
             │ 1:N
             └── saas_customers ──┐
                                  │ 1:N
                                  └── saas_mrr_history
                                        │
                                        └── change_type:
                                            new / expansion / contraction / churn / reactivation
```

## テーブル定義

| テーブル | 件数 | 概要 |
|---------|:---:|------|
| `saas_plans` | 3 | 料金プラン（Starter / Professional / Enterprise） |
| `saas_customers` | 40 | 顧客の契約情報・契約日・解約日 |
| `saas_mrr_history` | 88 | 月次MRR変動履歴（新規/拡張/縮小/解約） |

## クエリ一覧

| # | ファイル | 分析テーマ | 使用テクニック | ビジネス価値 |
|---|---------|-----------|--------------|------------|
| 01 | `01_monthly_mrr.sql` | 月次MRR推移 | SUM() OVER (累積), LAG() | 事業成長トレンドの定量化 |
| 02 | `02_mrr_breakdown.sql` | MRR変動の内訳 | 条件付き集計(CASE+SUM) | 増減要因の可視化 |
| 03 | `03_monthly_churn_rate.sql` | 月次チャーンレート | CTE, サブクエリ | 顧客維持の健全性評価 |
| 04 | `04_customer_ltv.sql` | 顧客LTV推計 | CROSS JOIN, NULLIF | CAC上限の判断材料 |
| 05 | `05_plan_comparison.sql` | プラン別比較 | LEFT JOIN, GROUP BY | プラン別の収益性・リスク分析 |

## 主要SaaS指標の解説

| 指標 | 略称 | 意味 |
|------|------|------|
| Monthly Recurring Revenue | MRR | 月次経常収益 |
| Average Revenue Per User | ARPU | 顧客あたり平均月次収益 |
| Churn Rate | - | 月次解約率（低いほど健全） |
| Customer Lifetime Value | LTV | 顧客が生涯で支払う推定総額 |
| Customer Acquisition Cost | CAC | 顧客獲得コスト（LTV > CACが必須条件） |

## 実行方法

```bash
# 1. スキーマ作成
mysql -u root sql_portfolio < saas_metrics/schema/create_tables.sql

# 2. データ投入（LOAD DATA または MySQL Workbenchの Table Data Import Wizard）

# 3. クエリ実行
mysql -u root sql_portfolio < saas_metrics/queries/01_monthly_mrr.sql
```
