/*
=============================================================================
Snowflake MLOps ハンズオン - クリーンナップ
=============================================================================
このスクリプトは、ハンズオンで作成したリソースを削除します。

⚠️ 注意: このスクリプトを実行すると、すべてのデータが削除されます！
=============================================================================
*/

-- ============================================
-- 1. 環境設定
-- ============================================
USE ROLE ACCOUNTADMIN;

-- ============================================
-- 2. Streamlitアプリの削除
-- ============================================
DROP STREAMLIT IF EXISTS MLOPS_HOL_DB.FEATURE_STORE.EXPERIMENT_VIEWER;

-- ============================================
-- 3. Notebookの削除
-- ============================================
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."06_EXPERIMENT_VIEWER_APP";

-- ============================================
-- 4. Git Repositoryの削除
-- ============================================
DROP GIT REPOSITORY IF EXISTS MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO_KE;

-- ============================================
-- 5. API Integrationの削除
-- ============================================
DROP API INTEGRATION IF EXISTS GIT_API_INTEGRATION_KE;

-- ============================================
-- 6. External Access Integration の削除（作成した場合のみ）
-- ============================================
DROP EXTERNAL ACCESS INTEGRATION IF EXISTS PYPI_ACCESS_INTEGRATION;
DROP NETWORK RULE IF EXISTS PYPI_NETWORK_RULE;

-- ============================================
-- 7. データベースの削除（すべてのスキーマ・テーブルも削除）
-- ============================================
DROP DATABASE IF EXISTS MLOPS_HOL_DB;

-- ============================================
-- 8. ウェアハウスの削除
-- ============================================
DROP WAREHOUSE IF EXISTS MLOPS_HOL_PYTHON_WH;
DROP WAREHOUSE IF EXISTS MLOPS_HOL_SQL_WH;

-- ============================================
-- 9. ロールの削除
-- ============================================
DROP ROLE IF EXISTS MLOPS_HOL_ROLE;

-- ============================================
-- 完了
-- ============================================
SELECT '🧹 クリーンナップ完了！すべてのリソースが削除されました。' AS STATUS;
