/*
=============================================================================
Snowflake MLOps ハンズオン - Streamlit Experiment Viewer 作成
=============================================================================
このスクリプトは、Section 4 (Experiment Tracking) 実行後に実行してください。
Experiment Viewer Streamlitアプリを自動作成します。

📌 前提条件:
   - setup.sql が実行済みであること
   - 04_EXPERIMENT_TRACKING が実行済みであること（EXPERIMENT_RESULTSテーブルが必要）

📌 作成されるもの:
   - Streamlit App: EXPERIMENT_VIEWER
=============================================================================
*/

-- ============================================
-- 1. 環境設定
-- ============================================
USE ROLE ACCOUNTADMIN;
USE DATABASE MLOPS_HOL_DB;
USE SCHEMA FEATURE_STORE;

-- Gitリポジトリを最新に同期
ALTER GIT REPOSITORY MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO_KE FETCH;

-- ============================================
-- 2. Streamlit App の作成
-- ============================================

-- Experiment Viewer アプリを作成
CREATE OR REPLACE STREAMLIT MLOPS_HOL_DB.FEATURE_STORE.EXPERIMENT_VIEWER
  FROM '@MLOPS_HOL_DB.PUBLIC.MLOPS_HOL_REPO_KE/branches/main/streamlit/'
  MAIN_FILE = 'experiment_viewer.py'
  QUERY_WAREHOUSE = MLOPS_HOL_SQL_WH
  COMMENT = 'MLOps Hands-on - Experiment Viewer';

-- ============================================
-- 3. 権限付与
-- ============================================
GRANT USAGE ON STREAMLIT MLOPS_HOL_DB.FEATURE_STORE.EXPERIMENT_VIEWER TO ROLE MLOPS_HOL_ROLE;

-- ============================================
-- 4. 確認
-- ============================================
SHOW STREAMLITS IN SCHEMA MLOPS_HOL_DB.FEATURE_STORE;

SELECT '🎉 Experiment Viewer 作成完了！' AS STATUS;

/*
=============================================================================
✅ 作成完了！

📌 アプリを開く方法:
   Snowsight左メニュー → Projects → Streamlit → EXPERIMENT_VIEWER

📌 機能:
   - 📊 比較ビュー: 全Runのメトリクス比較、過学習検出
   - 🔍 詳細ビュー: 個別Runのパラメータ、特徴量重要度、SHAP値
=============================================================================
*/

