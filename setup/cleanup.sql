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
-- 2. Notebookの削除
-- ============================================
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."01_DATA_EXPLORATION";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."02_FEATURE_STORE";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."03_MODEL_TRAINING";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."04_EXPERIMENT_TRACKING";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."05_MODEL_REGISTRY";
DROP NOTEBOOK IF EXISTS MLOPS_HOL_DB.NOTEBOOKS."06_EXPERIMENT_VIEWER_APP";

-- ============================================
-- 3. Streamlit Appの削除
-- ============================================
DROP STREAMLIT IF EXISTS MLOPS_HOL_DB.FEATURE_STORE.EXPERIMENT_VIEWER;

-- ============================================
-- 4. Git Repositoryの削除
-- ============================================
DROP GIT REPOSITORY IF EXISTS MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO_KE;

-- ============================================
-- 5. API Integrationの削除
-- ============================================
DROP API INTEGRATION IF EXISTS GIT_API_INTEGRATION_KE;

-- ============================================
-- 6. データベースの削除（すべてのスキーマ・テーブルも削除）
-- ============================================
DROP DATABASE IF EXISTS MLOPS_HOL_DB;

-- ============================================
-- 7. コンピュートプールの削除
-- ============================================
DROP COMPUTE POOL IF EXISTS MLOPS_HOL_COMPUTE_POOL;

-- ============================================
-- 8. ウェアハウスの削除
-- ============================================
DROP WAREHOUSE IF EXISTS MLOPS_HOL_SQL_WH;

-- ============================================
-- 9. ロールの削除
-- ============================================
DROP ROLE IF EXISTS MLOPS_HOL_ROLE;

-- ============================================
-- 完了
-- ============================================
SELECT '🧹 クリーンナップ完了！すべてのリソースが削除されました。' AS STATUS;
