/*
=============================================================================
Snowflake MLOps ハンズオン - データロード
=============================================================================
このスクリプトは、GitHubリポジトリのCSVデータをテーブルにロードします。

📌 データソース: GitHub リポジトリ内の data/*.csv
📌 チャーンラベル: Notebook (01_data_exploration) で作成
📌 特徴量計算: Notebook (02_feature_store) で実施

データ構成:
  - customers.csv: 顧客マスタ（3,000件）
  - orders.csv: 注文履歴（約20,000件）
  - ※ チャーンラベルはNotebook内で作成します

所要時間: 約30秒
=============================================================================
*/

-- ============================================
-- 0. 環境設定
-- ============================================
USE ROLE MLOPS_HOL_ROLE;
USE DATABASE MLOPS_HOL_DB;
USE SCHEMA PREP_DATA;
USE WAREHOUSE MLOPS_HOL_SQL_WH;

-- ============================================
-- 1. ファイルフォーマットの作成
-- ============================================
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL');

-- ============================================
-- 2. 顧客データのロード
-- ============================================
-- Git リポジトリから直接 SELECT して CREATE TABLE
CREATE OR REPLACE TABLE CUSTOMERS AS
SELECT 
    $1::VARCHAR AS CUSTOMER_ID,
    $2::VARCHAR AS SEGMENT,
    $3::DATE AS REGISTRATION_DATE,
    $4::VARCHAR AS REGION
FROM @MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/data/customers.csv
(FILE_FORMAT => CSV_FORMAT);

SELECT '顧客データ' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMERS;

-- ============================================
-- 3. 注文データのロード
-- ============================================
CREATE OR REPLACE TABLE ORDERS AS
SELECT 
    $1::VARCHAR AS ORDER_ID,
    $2::VARCHAR AS CUSTOMER_ID,
    $3::DATE AS ORDER_DATE,
    $4::FLOAT AS ORDER_AMOUNT,
    $5::VARCHAR AS STATUS
FROM @MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO/branches/main/data/orders.csv
(FILE_FORMAT => CSV_FORMAT);

SELECT '注文データ' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ORDERS;

-- ============================================
-- 4. データ確認
-- ============================================

-- 期間別注文数
SELECT 
    CASE 
        WHEN ORDER_DATE < '2024-01-01' THEN '2023年'
        WHEN ORDER_DATE <= '2024-06-30' THEN '2024年前半'
        ELSE '2024年後半'
    END AS PERIOD,
    COUNT(*) AS ORDER_COUNT
FROM ORDERS
GROUP BY 1
ORDER BY 1;

-- サンプルデータ
SELECT * FROM CUSTOMERS LIMIT 5;
SELECT * FROM ORDERS LIMIT 5;

SELECT '🎉 データロード完了' AS STATUS;
SELECT '💡 次のステップ: 01_DATA_EXPLORATION Notebook でチャーンラベルを作成してください' AS NEXT_STEP;

/*
=============================================================================
作成されたテーブル:
  - CUSTOMERS: 顧客マスタ（3,000件）
  - ORDERS: 注文履歴（約20,000件）

次のステップ:
  1. setup/02_setup_git_and_notebooks.sql を実行
  2. 01_DATA_EXPLORATION Notebook でチャーンの定義を決め、ラベルを作成
  3. 02_FEATURE_STORE Notebook で特徴量を作成
=============================================================================
*/
