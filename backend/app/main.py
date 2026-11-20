
import os

import psycopg
from fastapi import FastAPI, HTTPException

app = FastAPI(
    title="Drink Store API",
    description="Distributed Beverage Store Management System",
    version="1.0.0"
)


def get_db_connection():
    return psycopg.connect(
        host=os.getenv("DATABASE_HOST"),
        port=os.getenv("DATABASE_PORT"),
        dbname=os.getenv("DATABASE_NAME"),
        user=os.getenv("DATABASE_USER"),
        password=os.getenv("DATABASE_PASSWORD"),
        connect_timeout=5
    )


@app.get("/")
def root():
    return {
        "message": "Drink Store API is running",
        "status": "ok"
    }


@app.get("/api/health")
def health():
    return {
        "service": "backend",
        "status": "healthy"
    }


# =========================================
# 1. Get All Stores
# =========================================

@app.get("/api/stores")
def get_stores():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT
                        store_id,
                        store_name,
                        city,
                        store_type,
                        is_active
                    FROM stores
                    ORDER BY store_id;
                """)

                rows = cursor.fetchall()

                stores = [
                    {
                        "store_id": row[0],
                        "store_name": row[1],
                        "city": row[2],
                        "store_type": row[3],
                        "is_active": row[4]
                    }
                    for row in rows
                ]

        return stores

    except psycopg.Error as e:
        raise HTTPException(
            status_code=503,
            detail="Database connection or query failed"
        ) from e


# =========================================
# 2. Get Products By Store
# =========================================

@app.get("/api/stores/{store_id}/products")
def get_store_products(store_id: str):
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # 查詢指定門市的供應商品
                cursor.execute("""
                    SELECT
                        p.product_id,
                        p.product_code,
                        p.product_name,
                        p.description,
                        p.is_special,
                        sp.price,
                        sp.is_available
                    FROM store_products sp
                    JOIN products p
                        ON sp.product_id = p.product_id
                    JOIN stores s
                        ON sp.store_id = s.store_id
                    WHERE sp.store_id = %s
                      AND sp.is_available = TRUE
                      AND s.is_active = TRUE
                    ORDER BY p.is_special, p.product_id;
                """, (store_id,))

                rows = cursor.fetchall()

                products = [
                    {
                        "product_id": row[0],
                        "product_code": row[1],
                        "product_name": row[2],
                        "description": row[3],
                        "is_special": row[4],
                        "price": float(row[5]),
                        "is_available": row[6]
                    }
                    for row in rows
                ]

                # 如果沒有商品，再確認門市是否存在
                if not products:
                    cursor.execute("""
                        SELECT 1
                        FROM stores
                        WHERE store_id = %s;
                    """, (store_id,))

                    store_exists = cursor.fetchone()

                    if not store_exists:
                        raise HTTPException(
                            status_code=404,
                            detail="Store not found"
                        )

        return products

    except psycopg.Error as e:
        raise HTTPException(
            status_code=503,
            detail="Database connection or query failed"
        ) from e
