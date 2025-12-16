/*
=============================================================================
Snowflake MLOps ハンズオン - 環境セットアップ（オールインワン）
=============================================================================
このスクリプト1つで、ハンズオンに必要な環境がすべて構築されます。

📌 実行方法:
   1. このスクリプト全体をコピー
   2. Snowsight で新しいワークシートを作成
   3. 貼り付けて「Run All」で実行

📌 作成されるもの:
   - Git API統合 & Gitリポジトリ
   - データベース & スキーマ
   - コンピュートプール（Notebook用 - コンテナランタイム）
   - ウェアハウス（SQLクエリ用 XS）
   - 顧客・注文データ（CSVからロード）
   - 5つのNotebook

所要時間: 約2分
=============================================================================
*/

-- ============================================
-- 1. Git API統合 & Gitリポジトリ
-- ============================================
USE ROLE ACCOUNTADMIN;

-- Git API統合の作成
CREATE OR REPLACE API INTEGRATION GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-kenokizono/')
  ENABLED = TRUE;

-- データベース作成（Gitリポジトリ用）
CREATE DATABASE IF NOT EXISTS MLOPS_HOL_DB
    COMMENT = 'Snowflake MLOps Hands-on Lab Database';

-- Gitリポジトリの登録
CREATE OR REPLACE GIT REPOSITORY MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO
  API_INTEGRATION = GIT_API_INTEGRATION
  ORIGIN = 'https://github.com/sfc-gh-kenokizono/mlops_snowflake_handson.git';

-- リポジトリを最新に同期
ALTER GIT REPOSITORY MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO FETCH;

SELECT '✅ Step 1: Git統合完了' AS STATUS;

-- ============================================
-- 2. ロール、コンピュートプール、ウェアハウスの作成
-- ============================================

-- ハンズオン用ロール
CREATE ROLE IF NOT EXISTS MLOPS_HOL_ROLE;
GRANT ROLE MLOPS_HOL_ROLE TO ROLE ACCOUNTADMIN;

-- Notebook用コンピュートプール（コンテナランタイム）
-- 起動が早く、コスト効率が良い
CREATE COMPUTE POOL IF NOT EXISTS MLOPS_HOL_COMPUTE_POOL
  MIN_NODES = 1
  MAX_NODES = 10
  INSTANCE_FAMILY = CPU_X64_M
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300
  COMMENT = 'MLOps HOL - Notebook Container Runtime';

-- SQLクエリ用ウェアハウス（XSサイズ）
CREATE WAREHOUSE IF NOT EXISTS MLOPS_HOL_SQL_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'MLOps HOL - SQL Queries';

SELECT '✅ Step 2: コンピュートプール・ウェアハウス作成完了' AS STATUS;

-- ============================================
-- 3. スキーマの作成
-- ============================================
USE DATABASE MLOPS_HOL_DB;

CREATE SCHEMA IF NOT EXISTS PREP_DATA
    COMMENT = '前処理済みデータ格納用';

CREATE SCHEMA IF NOT EXISTS FEATURE_STORE
    COMMENT = 'Feature Store用';

CREATE SCHEMA IF NOT EXISTS MODEL_REGISTRY
    COMMENT = 'Model Registry用';

CREATE SCHEMA IF NOT EXISTS EXPERIMENTS
    COMMENT = 'Experiment Tracking用';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = '分析結果・マーケティングリスト格納用';

CREATE SCHEMA IF NOT EXISTS NOTEBOOKS
    COMMENT = 'Notebook格納用';

SELECT '✅ Step 3: スキーマ作成完了' AS STATUS;

-- ============================================
-- 4. 権限の付与
-- ============================================

-- データベース権限
GRANT USAGE ON DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- スキーマ権限
GRANT ALL ON ALL SCHEMAS IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- テーブル権限
GRANT ALL ON ALL TABLES IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- ウェアハウス権限
GRANT USAGE ON WAREHOUSE MLOPS_HOL_SQL_WH TO ROLE MLOPS_HOL_ROLE;

-- コンピュートプール権限
GRANT USAGE, MONITOR ON COMPUTE POOL MLOPS_HOL_COMPUTE_POOL TO ROLE MLOPS_HOL_ROLE;

-- モデル・動的テーブル作成権限
GRANT CREATE MODEL ON SCHEMA MLOPS_HOL_DB.MODEL_REGISTRY TO ROLE MLOPS_HOL_ROLE;
GRANT CREATE DYNAMIC TABLE ON SCHEMA MLOPS_HOL_DB.FEATURE_STORE TO ROLE MLOPS_HOL_ROLE;

SELECT '✅ Step 4: 権限付与完了' AS STATUS;

-- ============================================
-- 5. データのロード
-- ============================================
USE SCHEMA PREP_DATA;
USE WAREHOUSE MLOPS_HOL_SQL_WH;

-- ファイルフォーマット
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL');

-- 顧客データ
CREATE OR REPLACE TABLE CUSTOMERS AS
SELECT 
    $1::VARCHAR AS CUSTOMER_ID,
    $2::VARCHAR AS SEGMENT,
    $3::DATE AS REGISTRATION_DATE,
    $4::VARCHAR AS REGION
FROM @MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/data/customers.csv
(FILE_FORMAT => CSV_FORMAT);

-- 注文データ
CREATE OR REPLACE TABLE ORDERS AS
SELECT 
    $1::VARCHAR AS ORDER_ID,
    $2::VARCHAR AS CUSTOMER_ID,
    $3::DATE AS ORDER_DATE,
    $4::FLOAT AS ORDER_AMOUNT,
    $5::VARCHAR AS STATUS
FROM @MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/data/orders.csv
(FILE_FORMAT => CSV_FORMAT);

SELECT '✅ Step 5: データロード完了' AS STATUS;
SELECT 'CUSTOMERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMERS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS;

-- ============================================
-- 6. Notebookの作成（コンテナランタイム）
-- ============================================

-- Section 1: データ探索
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '01_data_exploration.ipynb'
  RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
  COMPUTE_POOL = MLOPS_HOL_COMPUTE_POOL
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION" ADD LIVE VERSION FROM LAST;

-- Section 2: Feature Store
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '02_feature_store.ipynb'
  RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
  COMPUTE_POOL = MLOPS_HOL_COMPUTE_POOL
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE" ADD LIVE VERSION FROM LAST;

-- Section 3: モデル学習
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '03_model_training.ipynb'
  RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
  COMPUTE_POOL = MLOPS_HOL_COMPUTE_POOL
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING" ADD LIVE VERSION FROM LAST;

-- Section 4: Experiment Tracking
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '04_experiment_tracking.ipynb'
  RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
  COMPUTE_POOL = MLOPS_HOL_COMPUTE_POOL
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING" ADD LIVE VERSION FROM LAST;

-- Section 5: Model Registry
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '05_model_registry.ipynb'
  RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
  COMPUTE_POOL = MLOPS_HOL_COMPUTE_POOL
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY" ADD LIVE VERSION FROM LAST;

SELECT '✅ Step 6: Notebook作成完了（コンテナランタイム）' AS STATUS;

-- ============================================
-- 7. 最終確認
-- ============================================
USE ROLE MLOPS_HOL_ROLE;
USE DATABASE MLOPS_HOL_DB;
USE SCHEMA PREP_DATA;
USE WAREHOUSE MLOPS_HOL_SQL_WH;

SHOW NOTEBOOKS IN SCHEMA MLOPS_HOL_DB.NOTEBOOKS;
SHOW COMPUTE POOLS LIKE 'MLOPS_HOL%';

SELECT '🎉 セットアップ完了！' AS STATUS;

/*
=============================================================================
✅ セットアップ完了！

📌 次のステップ:
   Snowsight の Projects → Notebooks からNotebookを開いてください

📌 実行順序:
   1. 01_DATA_EXPLORATION  - データ探索 + チャーンラベル作成
   2. 02_FEATURE_STORE     - 特徴量作成 + Feature Store登録
   3. 03_MODEL_TRAINING    - モデル学習 + SHAP解析
   4. 04_EXPERIMENT_TRACKING - 複数実験の比較
   5. 05_MODEL_REGISTRY    - モデル登録 + 本番推論

📌 ランタイム:
   - Notebook: コンピュートプール（コンテナランタイム）
   - SQLクエリ: MLOPS_HOL_SQL_WH（XSmall）

📌 クリーンナップ:
   ハンズオン終了後、cleanup.sql を実行してリソースを削除できます
=============================================================================
*/
