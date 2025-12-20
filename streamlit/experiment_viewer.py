"""
🔬 Experiment Viewer - MLOps Hands-on Lab
================================================
Section 4 (Experiment Tracking) の実験結果を可視化するStreamlitアプリ

機能:
- 📊 比較ビュー: 全Runのメトリクス比較、過学習検出
- 🔍 詳細ビュー: 個別Runのパラメータ、特徴量重要度、SHAP値
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import json
import altair as alt

# ページ設定
st.set_page_config(
    page_title="Experiment Viewer",
    page_icon="🔬",
    layout="wide"
)

# セッション取得
session = get_active_session()

st.title("🔬 Experiment Viewer")
st.caption("MLOps Hands-on Lab - 実験結果ビューア")

# データ取得
try:
    df = session.table("MLOPS_HOL_DB.FEATURE_STORE.EXPERIMENT_RESULTS").to_pandas()
except Exception as e:
    st.error(f"❌ EXPERIMENT_RESULTSテーブルが見つかりません。先にSection 4 (04_EXPERIMENT_TRACKING) を実行してください。")
    st.stop()

if len(df) == 0:
    st.warning("⚠️ 実験結果がありません。Section 4 を実行してください。")
    st.stop()

# タブで切り替え
tab1, tab2 = st.tabs(["📊 比較ビュー", "🔍 詳細ビュー"])

# =====================================================
# 比較ビュー（全Run横並び）
# =====================================================
with tab1:
    st.header("📊 全Runの比較")
    
    # メトリクス比較テーブル（過学習チェック付き）
    columns_to_show = ["RUN_NAME", "F1_SCORE", "ROC_AUC", "ACCURACY"]
    column_names = ["Run", "Test F1", "ROC-AUC", "Accuracy"]
    
    # TRAIN_F1_SCORE, OVERFIT_GAP_F1 があれば追加
    if "TRAIN_F1_SCORE" in df.columns:
        columns_to_show = ["RUN_NAME", "F1_SCORE", "TRAIN_F1_SCORE", "OVERFIT_GAP_F1", "ROC_AUC", "ACCURACY"]
        column_names = ["Run", "Test F1", "Train F1", "Gap", "ROC-AUC", "Accuracy"]
    
    comparison_df = df[columns_to_show].copy()
    comparison_df.columns = column_names
    st.dataframe(comparison_df, use_container_width=True, hide_index=True)
    
    if "TRAIN_F1_SCORE" in df.columns:
        st.caption("💡 Gap = Train F1 - Test F1（大きいほど過学習の可能性）")
    
    st.divider()
    
    # メトリクス棒グラフ比較
    st.subheader("📈 メトリクス比較")
    
    metrics_data = []
    for _, row in df.iterrows():
        run_name = row["RUN_NAME"].split("_")[0]
        metrics_data.append({"Run": run_name, "Metric": "F1", "Value": row["F1_SCORE"]})
        metrics_data.append({"Run": run_name, "Metric": "ROC-AUC", "Value": row["ROC_AUC"]})
        metrics_data.append({"Run": run_name, "Metric": "Accuracy", "Value": row["ACCURACY"]})
    
    metrics_df = pd.DataFrame(metrics_data)
    
    chart = alt.Chart(metrics_df).mark_bar().encode(
        x=alt.X("Run:N"),
        y=alt.Y("Value:Q", scale=alt.Scale(domain=[0, 1])),
        color=alt.Color("Run:N"),
        column=alt.Column("Metric:N")
    ).properties(width=150, height=300)
    st.altair_chart(chart)
    
    st.divider()
    
    # 特徴量重要度比較
    st.subheader("📈 特徴量重要度 比較")
    
    imp_data = []
    for _, row in df.iterrows():
        run_name = row["RUN_NAME"].split("_")[0]
        importance = json.loads(row["FEATURE_IMPORTANCE"])
        for feat, val in importance.items():
            imp_data.append({"Run": run_name, "Feature": feat, "Importance": val})
    
    imp_df = pd.DataFrame(imp_data)
    
    imp_chart = alt.Chart(imp_df).mark_bar().encode(
        x=alt.X("Importance:Q"),
        y=alt.Y("Feature:N", sort="-x"),
        color=alt.Color("Run:N"),
        row=alt.Row("Run:N")
    ).properties(height=150)
    st.altair_chart(imp_chart, use_container_width=True)

# =====================================================
# 詳細ビュー（1Run詳細）
# =====================================================
with tab2:
    st.header("🔍 Run詳細")
    
    selected_run = st.selectbox("Run名", df["RUN_NAME"].tolist())
    run_data = df[df["RUN_NAME"] == selected_run].iloc[0]
    
    # メトリクス
    col1, col2, col3, col4, col5 = st.columns(5)
    col1.metric("F1 Score", f"{run_data['F1_SCORE']:.4f}")
    col2.metric("ROC-AUC", f"{run_data['ROC_AUC']:.4f}")
    col3.metric("Accuracy", f"{run_data['ACCURACY']:.4f}")
    col4.metric("Precision", f"{run_data['PRECISION']:.4f}")
    col5.metric("Recall", f"{run_data['RECALL']:.4f}")
    
    # 過学習指標（あれば）
    if "TRAIN_F1_SCORE" in df.columns:
        st.divider()
        col_t1, col_t2, col_t3 = st.columns(3)
        col_t1.metric("Train F1", f"{run_data['TRAIN_F1_SCORE']:.4f}")
        col_t2.metric("Test F1", f"{run_data['F1_SCORE']:.4f}")
        gap = run_data['OVERFIT_GAP_F1']
        col_t3.metric("過学習Gap", f"{gap:.4f}", delta=f"{gap:.4f}" if gap > 0.05 else None, delta_color="inverse")
    
    st.divider()
    
    col_left, col_right = st.columns(2)
    
    with col_left:
        st.subheader("⚙️ パラメータ")
        st.json(json.loads(run_data['PARAMS']))
    
    with col_right:
        st.subheader("📈 特徴量重要度")
        importance = json.loads(run_data['FEATURE_IMPORTANCE'])
        imp_df = pd.DataFrame({
            "Feature": list(importance.keys()),
            "Importance": list(importance.values())
        }).sort_values("Importance", ascending=False)
        
        chart = alt.Chart(imp_df).mark_bar(color="steelblue").encode(
            x=alt.X("Importance:Q"),
            y=alt.Y("Feature:N", sort="-x")
        ).properties(height=250)
        st.altair_chart(chart, use_container_width=True)
    
    st.divider()
    
    # SHAP値
    st.subheader("🔍 SHAP値（平均絶対値）")
    shap_imp = json.loads(run_data['SHAP_IMPORTANCE'])
    shap_df = pd.DataFrame({
        "Feature": list(shap_imp.keys()),
        "SHAP": list(shap_imp.values())
    }).sort_values("SHAP", ascending=False)
    
    shap_chart = alt.Chart(shap_df).mark_bar(color="coral").encode(
        x=alt.X("SHAP:Q"),
        y=alt.Y("Feature:N", sort="-x")
    ).properties(height=250)
    st.altair_chart(shap_chart, use_container_width=True)
    
    st.caption("💡 SHAP値は各特徴量がモデル予測にどれだけ影響したかを示します")
    
    st.divider()
    
    with st.expander("📋 データセット情報"):
        st.json(json.loads(run_data['DATASET_INFO']))

st.divider()
st.caption("🔬 MLOps Hands-on Lab - Experiment Viewer | Powered by Streamlit in Snowflake")

