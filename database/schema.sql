
-- =========================================
-- Drink Store Distributed System
-- Database Schema
-- PostgreSQL 16
-- =========================================

-- 1. Stores
CREATE TABLE IF NOT EXISTS stores (
    store_id VARCHAR(50) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    store_type VARCHAR(20) NOT NULL DEFAULT 'branch',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_store_type
        CHECK (store_type IN ('headquarters', 'branch', 'franchise'))
);

-- 2. Products
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_special BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Store Products
CREATE TABLE IF NOT EXISTS store_products (
    store_id VARCHAR(50) NOT NULL,
    product_id INTEGER NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    PRIMARY KEY (store_id, product_id),

    FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT chk_product_price
        CHECK (price >= 0)
);

-- 4. Orders
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGSERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    store_id VARCHAR(50) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'paid',
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    CONSTRAINT chk_order_status
        CHECK (status IN ('pending', 'paid', 'cancelled')),

    CONSTRAINT chk_order_amount
        CHECK (total_amount >= 0)
);

-- 5. Order Items
CREATE TABLE IF NOT EXISTS order_items (
    item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_subtotal CHECK (subtotal >= 0)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_store_date
ON orders(store_id, ordered_at);

CREATE INDEX IF NOT EXISTS idx_orders_status
ON orders(status);

CREATE INDEX IF NOT EXISTS idx_order_items_order
ON order_items(order_id);

-- 6. Monthly Revenue View

CREATE OR REPLACE VIEW monthly_store_revenue AS
SELECT
    s.store_id,
    s.store_name,
    DATE_TRUNC('month', CURRENT_TIMESTAMP) AS revenue_month,
    COALESCE(
        SUM(o.total_amount),
        0
    ) AS monthly_revenue
FROM stores s
LEFT JOIN orders o
    ON s.store_id = o.store_id
    AND o.status = 'paid'
    AND o.ordered_at >= DATE_TRUNC('month', CURRENT_TIMESTAMP)
    AND o.ordered_at < DATE_TRUNC('month', CURRENT_TIMESTAMP)
        + INTERVAL '1 month'
GROUP BY
    s.store_id,
    s.store_name;
