-- DELIVERED ORDERS VIEW
-- A reusable filtered dataset of clean, complete, delivered orders.
-- Excludes: undelivered orders, incomplete edge months (pre-Jan 2017 and post-Aug 2018) and orders without a delivery date.

CREATE OR REPLACE VIEW delivered_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp  >= '2017-01-01'
  AND o.order_purchase_timestamp  <  '2018-09-01'
  AND o.order_delivered_customer_date IS NOT NULL;