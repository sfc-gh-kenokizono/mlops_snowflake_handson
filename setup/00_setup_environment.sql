/*
=============================================================================
Snowflake MLOps ハンズオン - 環境セットアップ
=============================================================================
このスクリプトは、ハンズオンに必要なSnowflake環境を構築します。

📌 使用データ: GitHubリポジトリ内のCSVファイル
   - customers.csv: 顧客マスタ（3,000件）
   - orders.csv: 注文履歴（約20,000件）

📌 チャーンラベル: Notebook内で定義・作成（MLの重要なステップ！）

実行方法:
1. Snowsight または SnowSQL で ACCOUNTADMIN ロールで実行
2. 所要時間: 約1分

=============================================================================
*/

-- ============================================
-- 1. ロールとウェアハウスの設定
-- ============================================
USE ROLE ACCOUNTADMIN;

-- ハンズオン用のロール作成（オプション）
CREATE ROLE IF NOT EXISTS MLOPS_HOL_ROLE;
GRANT ROLE MLOPS_HOL_ROLE TO ROLE ACCOUNTADMIN;

-- Python/ML処理用ウェアハウス（Mサイズ - ハイパラチューニング等の重い処理用）
CREATE WAREHOUSE IF NOT EXISTS MLOPS_HOL_PYTHON_WH
    WITH WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'MLOps Hands-on Lab - Python/ML Processing';

-- SQLクエリ用ウェアハウス（XSサイズ - 軽量クエリ用）
CREATE WAREHOUSE IF NOT EXISTS MLOPS_HOL_SQL_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'MLOps Hands-on Lab - SQL Queries';

-- ============================================
-- 2. データベースとスキーマの作成
-- ============================================

-- メインデータベース
CREATE DATABASE IF NOT EXISTS MLOPS_HOL_DB
    COMMENT = 'Snowflake MLOps Hands-on Lab Database';

USE DATABASE MLOPS_HOL_DB;

-- スキーマの作成
CREATE SCHEMA IF NOT EXISTS PREP_DATA
    COMMENT = '前処理済みデータ格納用スキーマ';

CREATE SCHEMA IF NOT EXISTS FEATURE_STORE
    COMMENT = 'Feature Store用スキーマ';

CREATE SCHEMA IF NOT EXISTS MODEL_REGISTRY
    COMMENT = 'Model Registry用スキーマ';

CREATE SCHEMA IF NOT EXISTS EXPERIMENTS
    COMMENT = 'Experiment Tracking用スキーマ';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = '分析結果・マーケティングリスト格納用スキーマ';

-- ============================================
-- 3. 権限の付与
-- ============================================

-- データベースへの権限
GRANT USAGE ON DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- スキーマへの権限
GRANT ALL ON ALL SCHEMAS IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- テーブルへの権限
GRANT ALL ON ALL TABLES IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE MLOPS_HOL_DB TO ROLE MLOPS_HOL_ROLE;

-- ウェアハウスへの権限
GRANT USAGE ON WAREHOUSE MLOPS_HOL_PYTHON_WH TO ROLE MLOPS_HOL_ROLE;
GRANT USAGE ON WAREHOUSE MLOPS_HOL_SQL_WH TO ROLE MLOPS_HOL_ROLE;

-- モデル作成権限
GRANT CREATE MODEL ON SCHEMA MLOPS_HOL_DB.MODEL_REGISTRY TO ROLE MLOPS_HOL_ROLE;
GRANT CREATE DYNAMIC TABLE ON SCHEMA MLOPS_HOL_DB.FEATURE_STORE TO ROLE MLOPS_HOL_ROLE;

-- ============================================
-- 4. 設定の確認
-- ============================================

-- 作成したオブジェクトの確認
SHOW DATABASES LIKE 'MLOPS_HOL_DB';
SHOW SCHEMAS IN DATABASE MLOPS_HOL_DB;
SHOW WAREHOUSES LIKE 'MLOPS_HOL%';

-- 使用するコンテキストの設定
USE ROLE MLOPS_HOL_ROLE;
USE DATABASE MLOPS_HOL_DB;
USE SCHEMA PREP_DATA;
USE WAREHOUSE MLOPS_HOL_PYTHON_WH;

SELECT 
    '✅ 環境セットアップ完了！' AS STATUS,
    CURRENT_DATABASE() AS DATABASE_NAME,
    CURRENT_SCHEMA() AS SCHEMA_NAME,
    CURRENT_WAREHOUSE() AS PYTHON_WAREHOUSE,
    CURRENT_ROLE() AS ROLE_NAME;

/*
=============================================================================
次のステップ:
  setup/01_prepare_training_data.sql を実行してデータをロードしてください
=============================================================================
*/
