/*
=============================================================================
Snowflake MLOps ハンズオン - Git連携 & Notebook セットアップ
=============================================================================
このスクリプトは、GitリポジトリからSnowflake Notebookを自動作成します。
Notebookはウェアハウスランタイムで実行されます。

📌 前提条件:
   - 00_setup_environment.sql を実行済み
   - 01_prepare_training_data.sql を実行済み

所要時間: 約2分
=============================================================================
*/

-- ============================================
-- 1. 環境設定
-- ============================================
USE ROLE ACCOUNTADMIN;
USE DATABASE MLOPS_HOL_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE MLOPS_HOL_PYTHON_WH;

-- ============================================
-- 2. Git連携のAPI統合を作成
-- ============================================
CREATE OR REPLACE API INTEGRATION GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-kenokizono/')
  ENABLED = TRUE;

-- ============================================
-- 3. Git Repositoryの登録
-- ============================================
CREATE OR REPLACE GIT REPOSITORY MLOPS_HOL_REPO
  API_INTEGRATION = GIT_API_INTEGRATION
  ORIGIN = 'https://github.com/sfc-gh-kenokizono/mlops_snowflake_handson.git';

-- リポジトリの同期
ALTER GIT REPOSITORY MLOPS_HOL_REPO FETCH;

-- ファイル一覧確認
LS @MLOPS_HOL_REPO/branches/main/notebooks;

-- ============================================
-- 4. Notebookスキーマの作成
-- ============================================
CREATE SCHEMA IF NOT EXISTS MLOPS_HOL_DB.NOTEBOOKS;
GRANT ALL ON SCHEMA MLOPS_HOL_DB.NOTEBOOKS TO ROLE MLOPS_HOL_ROLE;

-- ============================================
-- 5. Notebookの作成（ウェアハウスランタイム）
-- ============================================
-- 2025_01以降: WAREHOUSE（Python用）とQUERY_WAREHOUSE（SQL用）を分離
--   WAREHOUSE: MLOPS_HOL_PYTHON_WH (M) - Python/ML処理用
--   QUERY_WAREHOUSE: MLOPS_HOL_SQL_WH (XS) - SQLクエリ用

-- Section 1: データ探索
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '01_data_exploration.ipynb'
  WAREHOUSE = MLOPS_HOL_PYTHON_WH
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION" ADD LIVE VERSION FROM LAST;

-- Section 2: Feature Store
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '02_feature_store.ipynb'
  WAREHOUSE = MLOPS_HOL_PYTHON_WH
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE" ADD LIVE VERSION FROM LAST;

-- Section 3: モデル学習
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '03_model_training.ipynb'
  WAREHOUSE = MLOPS_HOL_PYTHON_WH
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING" ADD LIVE VERSION FROM LAST;

-- Section 4: Experiment Tracking
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '04_experiment_tracking.ipynb'
  WAREHOUSE = MLOPS_HOL_PYTHON_WH
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING" ADD LIVE VERSION FROM LAST;

-- Section 5: Model Registry
CREATE OR REPLACE NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY"
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/notebooks/'
  MAIN_FILE = '05_model_registry.ipynb'
  WAREHOUSE = MLOPS_HOL_PYTHON_WH
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH;

ALTER NOTEBOOK MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY" ADD LIVE VERSION FROM LAST;

-- ============================================
-- 6. 確認
-- ============================================
SHOW NOTEBOOKS IN SCHEMA MLOPS_HOL_DB.NOTEBOOKS;

SELECT '✅ Git連携 & Notebook セットアップ完了！' AS STATUS;

/*
=============================================================================
次のステップ:
  Snowsight の Projects → Notebooks からNotebookを開いてください

📌 実行順序:
   1. 01_DATA_EXPLORATION
   2. 02_FEATURE_STORE
   3. 03_MODEL_TRAINING
   4. 04_EXPERIMENT_TRACKING
   5. 05_MODEL_REGISTRY

📦 パッケージについて:
   environment.yml により必要なパッケージは自動インストールされます

📋 ウェアハウス設定（2025_01以降）:
   - WAREHOUSE: Python/MLカーネル実行用
   - QUERY_WAREHOUSE: SQLクエリ実行用
=============================================================================
*/
