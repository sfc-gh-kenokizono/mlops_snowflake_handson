# Snowflake MLOps ハンズオン - デモスクリプト

## 📋 概要

**所要時間**: 約100分  
**対象者**: データサイエンティスト、MLエンジニア、データエンジニア

---

## 🎯 デモのゴール

> 「Snowflake上でMLOpsの一連のワークフローを体験し、Feature Store、Experiment Tracking、Model Registryの価値を理解する」

---

## 📖 デモストーリー

### 🎭 シナリオ説明（2分）

```
📢 説明ポイント:
「皆さんは小売会社『Snow Retail』のデータサイエンティストです。
2024年前半にアクティブだった顧客の一部が、後半に離反しています。
離反しそうな顧客を事前に特定し、リテンション施策を打ちたいと考えています。」

「今日は、データ探索からモデルの本番デプロイまで、
Snowflake上でMLOpsの一連のワークフローを体験していただきます。」
```

---

## Step 0: 環境セットアップ（5分）

### 実行
1. Snowsight を開く
2. 新しいワークシートを作成
3. `setup/setup.sql` をコピー＆ペースト
4. 「Run All」で実行

### 📢 説明ポイント
```
「このスクリプト1つで、必要な環境がすべて構築されます。
- Git連携でリポジトリを登録
- データベース、コンピュートプール（CPU_X64_M）の作成
- CSVデータのロード
- 6つのNotebookの自動作成（コンテナランタイムで実行）
約2分で完了します。」
```

### 確認
- 「🎉 セットアップ完了！」が表示されることを確認

---

## Step 1: データ探索 + チャーンラベル作成（15分）

### 実行
1. **Projects → Notebooks → 01_DATA_EXPLORATION** を開く
2. セルを順番に実行

### 📢 説明ポイント

#### 1.2 データの確認
```
「まず、顧客データと注文データを確認します。
- 顧客: 3,000件（セグメント、地域など）
- 注文: 約20,000件（注文日、金額、ステータス）」
```

#### 1.4 チャーンの定義（重要！）
```
「ここがMLの重要なポイントです。
『チャーン』をどう定義するか、ビジネス要件に基づいて決めます。

今回の定義:
- 2024年前半（1-6月）に注文があった顧客のうち
- 2024年後半（7-12月）に注文がなかった顧客 = チャーン

この定義に基づいて、ラベルを作成します。」
```

#### 1.5 チャーンラベルの保存
```
「作成したラベルをテーブルに保存します。
これが後の学習データの正解ラベルになります。」
```

### 📊 UI確認ポイント
- **Data → Databases → MLOPS_HOL_DB → PREP_DATA → Tables**
  - CUSTOMERS, ORDERS, CHURN_LABELS テーブルが作成されていることを確認

---

## Step 2: Feature Store（20分）

### 実行
1. **02_FEATURE_STORE** Notebookを開く
2. セルを順番に実行

### 📢 説明ポイント

#### 2.3 特徴量の計算
```
「顧客の行動を表すRFM特徴量を計算します。
- Recency: 最終注文からの日数（長い→チャーンしやすい）
- Frequency: 注文回数（少ない→チャーンしやすい）
- Monetary: 注文金額（低い→チャーンしやすい）」
```

#### 2.4-2.6 Feature Store登録
```
「計算した特徴量をFeature Storeに登録します。

Feature Storeの利点:
- 特徴量の一元管理
- チーム間での再利用
- 学習と推論での一貫性」
```

#### 2.7 バージョン管理（v1 → v2）
```
「特徴量を追加してv2を作成します。
- v1: 基本RFM特徴量（5個）
- v2: 返品率、セグメントを追加（8個）

Feature Storeではバージョン管理ができるので、
どの特徴量セットでモデルを学習したか追跡できます。」
```

### 📊 UI確認ポイント（重要！）
- **AI & ML → Feature Store** を開く
- 「CUSTOMER」Entityが登録されていることを確認
- 「CUSTOMER_FEATURES」のv1, v2が表示されることを確認

```
📢「Snowsight上でFeature Storeの内容を確認できます。
Entityと、そこに紐づくFeatureViewが一覧表示されます。
バージョンごとの特徴量の違いも確認できます。」
```

---

## Step 3: モデル学習（20分）

### 実行
1. **03_MODEL_TRAINING** Notebookを開く
2. セルを順番に実行（ハイパーパラメータチューニングに数分かかる）

### 📢 説明ポイント

#### 3.4 ハイパーパラメータチューニング
```
「RandomizedSearchCVで最適なパラメータを探索します。
5パターン × 3-Fold CV = 15回の学習を自動で実行します。
F1スコアを最適化しています。」
```

#### 3.6 Feature Importance
```
「どの特徴量が予測に重要かを可視化します。
DAYS_SINCE_LAST_ORDER（最終注文からの日数）が
最も重要な特徴量になっていることが多いです。」
```

#### 3.7 SHAP値
```
「SHAPはモデルの予測を解釈する手法です。
『なぜこの顧客がチャーンと予測されたのか？』を説明できます。
- 赤: チャーン方向に寄与
- 青: アクティブ方向に寄与」
```

---

## Step 4: Experiment Tracking（15分）

### 実行
1. **04_EXPERIMENT_TRACKING** Notebookを開く
2. セルを順番に実行

### 📢 説明ポイント

#### 4.4 実験の実行
```
「3つの異なるパラメータセットで実験を実行します。
- Baseline: デフォルトパラメータ
- DeepTree: 深い木（複雑なパターン学習）
- Conservative: 浅い木 + 低学習率（過学習防止）

各実験のパラメータとメトリクスを自動で記録します。」
```

#### 4.5 実験結果の比較
```
「実験結果を比較し、最良のモデルを選択します。
F1スコアを基準に選んでいます。」
```

### 📊 UI確認ポイント（重要！）
- **AI & ML → Experiments** を開く
- 「CHURN_PREDICTION_EXPERIMENT」を選択
- 3つのRunが表示されることを確認
- パラメータ・メトリクスの比較表を見せる

```
📢「Snowsight上で実験結果を一覧表示できます。
各Runのパラメータとメトリクスを比較し、
どのモデルが最良かを判断できます。
MLflowのような機能がSnowflake内に組み込まれています。」
```

---

## Step 5: Model Registry（10分）

### 実行
1. **05_MODEL_REGISTRY** Notebookを開く
2. セルを順番に実行

### 📢 説明ポイント

#### 5.3 モデル登録
```
「最良のモデルをModel Registryに登録します。
メトリクスやコメントも一緒に保存されます。」
```

#### 5.4 バージョン管理（v1 → v2）
```
「パラメータを改善してv2を作成します。
Feature Storeと同様に、モデルもバージョン管理できます。
- A/Bテスト
- ロールバック
- 監査
などに活用できます。」
```

#### 5.5-5.6 本番推論
```
「登録したモデルを使って、チャーンリスク顧客リストを作成します。
このリストをマーケティング部門に提供し、
リテンション施策を実行します。」
```

### 📊 UI確認ポイント（重要！）
- **AI & ML → Models** を開く
- 「CUSTOMER_CHURN_PREDICTOR」を選択
- v1, v2が表示されることを確認
- メトリクス、コメントを確認

```
📢「Model Registryでは、登録されたモデルの一覧、
各バージョンのメトリクス、説明などを確認できます。
本番環境でどのバージョンを使うかの管理もここで行えます。」
```

---

## Step 6: Experiment Viewer（10分）

### 実行
1. 06_EXPERIMENT_VIEWER_APP Notebookを開く
2. SQLセル（Cell 2）を実行
3. **Projects → Streamlit → EXPERIMENT_VIEWER** を開く

### 📢 説明ポイント

#### 6.1 SQLで自動作成
```
「このSQLセルを実行するだけで、
Streamlitアプリが自動作成されます。

Git統合を使っているので:
- コードを手動で貼り付ける必要なし
- バージョン管理も自動
- チーム全員が同じアプリを使える」
```

#### 6.2 比較ビュー
```
「比較ビューでは、全Runを一覧で比較できます。
- Test F1、Train F1、過学習Gap
- どのモデルが最も汎化性能が高いか一目でわかります
- 過学習しているモデルはGapの値で検出できます」
```

### 📊 UI確認ポイント
- **Projects → Streamlit** でEXPERIMENT_VIEWERが作成されていることを確認
- アプリを開き、比較ビュー・詳細ビューを切り替えてデモ

```
📢「Streamlit in Snowflakeを使うと、
データを移動せずにインタラクティブな可視化が可能です。
実験結果の比較や報告に活用できます。」
```

---

## 📊 最終成果物の確認（5分）

### Data → Tables で確認
| テーブル | スキーマ | 説明 |
|----------|----------|------|
| CHURN_LABELS | PREP_DATA | チャーンラベル |
| TRAINING_DATASET_V1 | FEATURE_STORE | 学習データ |
| MODEL_PREDICTIONS_V1 | ANALYTICS | 予測結果 |
| EXPERIMENT_RESULTS | EXPERIMENTS | 実験結果 |
| CHURN_RISK_CUSTOMERS | ANALYTICS | 施策対象リスト |

### 📢 まとめ
```
「本日のハンズオンで、以下を構築しました:

1. データ探索 → チャーンの定義・ラベル作成
2. Feature Store → 特徴量のバージョン管理
3. Model Training → ハイパラチューニング、SHAP解析
4. Experiment Tracking → 複数モデルの比較
5. Model Registry → モデルのバージョン管理、本番デプロイ
6. Experiment Viewer → Streamlitアプリで実験結果を可視化

すべてSnowflake上で完結しています。
データの移動なし、外部ツール不要でMLOpsを実現できます。」
```

---

## 🎁 おまけ: SQLからのモデル呼び出し

```sql
-- 新しい顧客データに対してチャーン予測
SELECT 
    CUSTOMER_ID,
    MLOPS_HOL_DB.MODEL_REGISTRY.CUSTOMER_CHURN_PREDICTOR!PREDICT(
        DAYS_SINCE_LAST_ORDER,
        TOTAL_ORDER_COUNT,
        ...
    ) AS CHURN_PREDICTION
FROM CUSTOMER_FEATURES_VIEW;
```

```
📢「登録したモデルはSQLから直接呼び出せます。
BIツールやダッシュボードからも利用可能です。」
```

---

## 📋 クリーンナップ

ハンズオン終了後:
```sql
-- cleanup.sql を実行
-- すべてのリソースが削除されます
```

---

## 📚 参考リンク

- [Snowflake ML Overview](https://docs.snowflake.com/en/developer-guide/snowflake-ml/overview)
- [Feature Store](https://docs.snowflake.com/en/developer-guide/snowflake-ml/feature-store/overview)
- [Model Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)
- [Experiments](https://docs.snowflake.com/en/developer-guide/snowflake-ml/experiments)
