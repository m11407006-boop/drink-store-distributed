
BEGIN;

-- =========================================
-- 1. Store Initial Data
-- =========================================

INSERT INTO stores
(store_id, store_name, city, store_type)
VALUES
('taoyuan_hq', '桃園總店', '桃園', 'headquarters'),
('taoyuan_1', '桃園1店', '桃園', 'branch'),
('taoyuan_2', '桃園2店', '桃園', 'branch'),
('taoyuan_3', '桃園3店', '桃園', 'branch'),
('taipei_1', '台北分店', '台北', 'branch'),
('taichung_1', '台中分店', '台中', 'branch'),
('tainan_1', '台南分店', '台南', 'branch')
ON CONFLICT (store_id) DO UPDATE SET
    store_name = EXCLUDED.store_name,
    city = EXCLUDED.city,
    store_type = EXCLUDED.store_type;

-- =========================================
-- 2. Shared Products
-- =========================================

INSERT INTO products
(product_code, product_name, description, is_special)
VALUES
('MILK_TEA', '奶茶', '開心奶茶', FALSE),
('BLACK_TEA', '紅茶', '快樂紅茶', FALSE),
('GREEN_TEA', '綠茶', '烏龍綠茶', FALSE),
('FLOWER_TEA', '花茶', '茉莉花茶', FALSE),
('SUGARCANE_TEA', '甘蔗茶', '甘蔗清茶', FALSE)
ON CONFLICT (product_code) DO UPDATE SET
    product_name = EXCLUDED.product_name,
    description = EXCLUDED.description,
    is_special = FALSE;

-- =========================================
-- 3. Store Special Products
-- =========================================

INSERT INTO products
(product_code, product_name, description, is_special)
VALUES
('SPECIAL_TAOYUAN_HQ', '桃園總店特調', '桃園總店專屬特調', TRUE),
('SPECIAL_TAOYUAN_1', '桃園1店特調', '桃園1店專屬特調', TRUE),
('SPECIAL_TAOYUAN_2', '桃園2店特調', '桃園2店專屬特調', TRUE),
('SPECIAL_TAOYUAN_3', '桃園3店特調', '桃園3店專屬特調', TRUE),
('SPECIAL_TAIPEI_1', '台北分店特調', '台北分店專屬特調', TRUE),
('SPECIAL_TAICHUNG_1', '台中分店特調', '台中分店專屬特調', TRUE),
('SPECIAL_TAINAN_1', '台南分店特調', '台南分店專屬特調', TRUE)
ON CONFLICT (product_code) DO UPDATE SET
    product_name = EXCLUDED.product_name,
    description = EXCLUDED.description,
    is_special = TRUE;

-- =========================================
-- 4. Store Product Prices
-- =========================================

-- All stores share five standard products.

INSERT INTO store_products
(store_id, product_id, price)
SELECT
    s.store_id,
    p.product_id,
    CASE p.product_code
        WHEN 'MILK_TEA' THEN 70
        WHEN 'BLACK_TEA' THEN 55
        WHEN 'GREEN_TEA' THEN 60
        WHEN 'FLOWER_TEA' THEN 70
        WHEN 'SUGARCANE_TEA' THEN 65
    END
FROM stores s
CROSS JOIN products p
WHERE p.product_code IN (
    'MILK_TEA',
    'BLACK_TEA',
    'GREEN_TEA',
    'FLOWER_TEA',
    'SUGARCANE_TEA'
)
ON CONFLICT (store_id, product_id)
DO UPDATE SET price = EXCLUDED.price;

-- Each store receives its own special product.

INSERT INTO store_products
(store_id, product_id, price)
SELECT
    s.store_id,
    p.product_id,
    60
FROM stores s
JOIN products p
    ON p.product_code = 'SPECIAL_' || UPPER(s.store_id)
ON CONFLICT (store_id, product_id)
DO UPDATE SET price = EXCLUDED.price;

-- =========================================
-- 5. Generate Demo Orders
-- =========================================

-- Two paid demo orders per store.
-- Total revenue per store: NT$3,510.
-- Dates are within the current month.

INSERT INTO orders
(order_number, store_id, total_amount, status, ordered_at)
SELECT
    'LAB-' || s.store_id || '-001',
    s.store_id,
    1610,
    'paid',
    DATE_TRUNC('month', CURRENT_TIMESTAMP) + INTERVAL '10 days'
FROM stores s
ON CONFLICT (order_number) DO NOTHING;

INSERT INTO orders
(order_number, store_id, total_amount, status, ordered_at)
SELECT
    'LAB-' || s.store_id || '-002',
    s.store_id,
    1900,
    'paid',
    DATE_TRUNC('month', CURRENT_TIMESTAMP) + INTERVAL '20 days'
FROM stores s
ON CONFLICT (order_number) DO NOTHING;

-- First order items:
-- Milk Tea 10, Black Tea 10, Green Tea 5,
-- Store Special 1.
-- Total: 1610.

WITH item_data AS (
    SELECT
        s.store_id,
        v.product_code,
        v.quantity,
        v.unit_price
    FROM stores s
    CROSS JOIN (
        VALUES
        ('MILK_TEA', 10, 70),
        ('BLACK_TEA', 10, 55),
        ('GREEN_TEA', 5, 60)
    ) AS v(product_code, quantity, unit_price)

    UNION ALL

    SELECT
        s.store_id,
        'SPECIAL_' || UPPER(s.store_id),
        1,
        60
    FROM stores s
)
INSERT INTO order_items
(order_id, product_id, quantity, unit_price, subtotal)
SELECT
    o.order_id,
    p.product_id,
    i.quantity,
    i.unit_price,
    i.quantity * i.unit_price
FROM item_data i
JOIN orders o
    ON o.order_number = 'LAB-' || i.store_id || '-001'
JOIN products p
    ON p.product_code = i.product_code
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items existing
    WHERE existing.order_id = o.order_id
      AND existing.product_id = p.product_id
);

-- Second order items:
-- Milk Tea 10, Black Tea 10, Green Tea 5,
-- Flower Tea 5.
-- Total: 1900.

WITH item_data AS (
    SELECT
        s.store_id,
        v.product_code,
        v.quantity,
        v.unit_price
    FROM stores s
    CROSS JOIN (
        VALUES
        ('MILK_TEA', 10, 70),
        ('BLACK_TEA', 10, 55),
        ('GREEN_TEA', 5, 60),
        ('FLOWER_TEA', 5, 70)
    ) AS v(product_code, quantity, unit_price)
)
INSERT INTO order_items
(order_id, product_id, quantity, unit_price, subtotal)
SELECT
    o.order_id,
    p.product_id,
    i.quantity,
    i.unit_price,
    i.quantity * i.unit_price
FROM item_data i
JOIN orders o
    ON o.order_number = 'LAB-' || i.store_id || '-002'
JOIN products p
    ON p.product_code = i.product_code
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items existing
    WHERE existing.order_id = o.order_id
      AND existing.product_id = p.product_id
);

COMMIT;

