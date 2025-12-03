#!/usr/bin/env python3
"""
デモデータ生成スクリプト

チャーン定義: 
  「2024年前半（1-6月）に注文があったが、2024年後半（7-12月）に注文がなかった顧客」

このスクリプトは customers.csv と orders.csv のみ生成します。
チャーンラベルは Notebook 内で計算します（MLの自然な流れを体験するため）
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

np.random.seed(42)

NUM_CUSTOMERS = 3000
TARGET_CHURN_RATE = 0.35  # 約35%のチャーン率を目指す

print("🔄 デモデータを生成中...")

# 出力ディレクトリ作成
os.makedirs('data', exist_ok=True)

# ============================================
# 1. 顧客データ生成
# ============================================
customer_ids = [f"CUST_{i:05d}" for i in range(1, NUM_CUSTOMERS + 1)]

# セグメントによってチャーンしやすさが異なる
# Basic: チャーンしやすい, Premium: チャーンしにくい
segments = np.random.choice(['Premium', 'Standard', 'Basic'], NUM_CUSTOMERS, p=[0.2, 0.5, 0.3])

# 登録日（1〜3年前）
registration_dates = [
    datetime(2024, 6, 30) - timedelta(days=np.random.randint(365, 1095))
    for _ in range(NUM_CUSTOMERS)
]

customers_df = pd.DataFrame({
    'CUSTOMER_ID': customer_ids,
    'SEGMENT': segments,
    'REGISTRATION_DATE': [d.strftime('%Y-%m-%d') for d in registration_dates],
    'REGION': np.random.choice(['East', 'West', 'North', 'South'], NUM_CUSTOMERS)
})

print(f"  顧客データ: {len(customers_df):,} 件")

# ============================================
# 2. チャーン顧客の決定（データ生成用）
# ============================================
# 各顧客がチャーンするかどうかを決定
# セグメントによってチャーン確率が異なる
churn_prob = {
    'Basic': 0.50,      # Basicは50%がチャーン
    'Standard': 0.35,   # Standardは35%
    'Premium': 0.15     # Premiumは15%
}

is_churned = []
for seg in segments:
    prob = churn_prob[seg]
    is_churned.append(np.random.random() < prob)

is_churned = np.array(is_churned)
print(f"  設計チャーン率: {is_churned.mean():.1%}")

# ============================================
# 3. 注文データ生成
# ============================================
orders = []
order_id = 1

for i, cust_id in enumerate(customer_ids):
    segment = segments[i]
    churned = is_churned[i]
    
    # 基本注文数（セグメントで変わる）
    base_orders = {'Premium': 12, 'Standard': 8, 'Basic': 4}[segment]
    
    # チャーン顧客は注文が少なめ
    if churned:
        num_orders = max(1, int(np.random.poisson(base_orders * 0.6)))
    else:
        num_orders = max(2, int(np.random.poisson(base_orders)))
    
    # 注文日を生成
    for _ in range(num_orders):
        if churned:
            # チャーン顧客: 2024年前半までしか注文しない（2024年後半は注文なし）
            # 2023年1月〜2024年6月の間でランダム
            days_before_cutoff = np.random.randint(180, 550)  # 2024/6/30から180〜550日前
            order_date = datetime(2024, 6, 30) - timedelta(days=days_before_cutoff)
            
            # ただし少なくとも1件は2024年前半に注文があることを保証
            if _ == 0:
                # 最初の注文は必ず2024年1月〜6月
                order_date = datetime(2024, 1, 1) + timedelta(days=np.random.randint(0, 180))
        else:
            # 非チャーン顧客: 2024年後半にも注文がある
            if _ == 0:
                # 少なくとも1件は2024年後半に注文
                order_date = datetime(2024, 7, 1) + timedelta(days=np.random.randint(0, 180))
            elif _ == 1:
                # 2件目は2024年前半に注文
                order_date = datetime(2024, 1, 1) + timedelta(days=np.random.randint(0, 180))
            else:
                # 残りは2023年〜2024年でランダム
                days_ago = np.random.randint(0, 730)
                order_date = datetime(2024, 12, 31) - timedelta(days=days_ago)
        
        # 金額（セグメントで変わる）
        base_amount = {'Premium': 300, 'Standard': 200, 'Basic': 100}[segment]
        amount = round(np.random.uniform(base_amount * 0.5, base_amount * 1.5), 2)
        
        # ステータス（チャーン顧客は返品率が高い）
        if churned:
            status = np.random.choice(['FULFILLED', 'RETURNED', 'CANCELLED'], p=[0.75, 0.18, 0.07])
        else:
            status = np.random.choice(['FULFILLED', 'RETURNED', 'CANCELLED'], p=[0.90, 0.07, 0.03])
        
        orders.append({
            'ORDER_ID': f"ORD_{order_id:06d}",
            'CUSTOMER_ID': cust_id,
            'ORDER_DATE': order_date.strftime('%Y-%m-%d'),
            'ORDER_AMOUNT': amount,
            'STATUS': status
        })
        order_id += 1

orders_df = pd.DataFrame(orders)
print(f"  注文データ: {len(orders_df):,} 件")

# ============================================
# 4. チャーン定義の検証
# ============================================
# 実際に注文データからチャーンを計算してみる
orders_df['ORDER_DATE'] = pd.to_datetime(orders_df['ORDER_DATE'])

# 2024年前半に注文がある顧客
h1_customers = set(orders_df[
    (orders_df['ORDER_DATE'] >= '2024-01-01') & 
    (orders_df['ORDER_DATE'] <= '2024-06-30')
]['CUSTOMER_ID'].unique())

# 2024年後半に注文がある顧客
h2_customers = set(orders_df[
    orders_df['ORDER_DATE'] >= '2024-07-01'
]['CUSTOMER_ID'].unique())

# チャーン = 前半に注文あり、後半に注文なし
actual_churn = h1_customers - h2_customers
actual_churn_rate = len(actual_churn) / len(h1_customers) if h1_customers else 0

print(f"\n=== チャーン検証 ===")
print(f"  2024年前半に注文した顧客: {len(h1_customers):,}")
print(f"  そのうち後半に注文なし: {len(actual_churn):,}")
print(f"  実際のチャーン率: {actual_churn_rate:.1%}")

# ============================================
# 5. CSV保存（ラベルは保存しない！）
# ============================================
orders_df['ORDER_DATE'] = orders_df['ORDER_DATE'].dt.strftime('%Y-%m-%d')
customers_df.to_csv('data/customers.csv', index=False)
orders_df.to_csv('data/orders.csv', index=False)

print(f"\n✅ データ生成完了!")
print(f"   - data/customers.csv ({len(customers_df):,} 件)")
print(f"   - data/orders.csv ({len(orders_df):,} 件)")
print(f"\n💡 チャーンラベルは Notebook 内で計算します")
print(f"   定義: 2024年前半に注文あり、後半に注文なし → チャーン")
