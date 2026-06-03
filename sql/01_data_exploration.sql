/* 
 DATA EXPLORATION & QUALITY CHECKS
Used to understand the dataset's structure, date range, completeness, 
and flag data quality issues before further analysis.
 */

-- 1. ROW COUNTS PER TABLE
-- Quick check to see if they match the Kaggle documentation
SELECT  'customers' AS table_name,  COUNT(*) AS row_count FROM customers
UNION ALL
SELECT  'orders',  COUNT(*) FROM orders
UNION ALL
SELECT  'order_items',  COUNT(*) FROM order_items
UNION ALL
SELECT  'order_payments',  COUNT(*) FROM order_payments
UNION ALL
SELECT  'order_reviews',  COUNT(*) FROM order_reviews
UNION ALL
SELECT  'products',  COUNT(*) FROM products
UNION ALL
SELECT  'sellers',  COUNT(*) FROM sellers
UNION ALL
SELECT  'category_translation',  COUNT(*) FROM category_translation;


-- 2. DATE RANGE OF THE DATASET
SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM orders;


-- 3. ORDER STATUS DISTRIBUTION
-- Tells us how much of the data is actually usable for revenue analysis
SELECT
	o.order_status,
	COUNT(*) AS order_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM orders o
GROUP BY o.order_status
ORDER BY pct_of_total DESC;


-- 4. NULL CHECK ON CRITICAL COLUMNS
-- Many orders were never delivered, and because of this their delivery date is NULL.
-- For further revenue or delivery time analysis this must be taken into account.
SELECT
	o.order_status,
	COUNT(*) AS total_orders,
	COUNT(order_approved_at) AS with_approval_date,
	COUNT(o.order_delivered_customer_date) AS with_delivery_date,
	COUNT(*) - COUNT(o.order_delivered_customer_date) AS without_delivery_date
FROM orders o 
GROUP BY o.order_status 
ORDER BY total_orders  DESC;


-- 5. DATA QUALITY: ORPHANED RECORDS
-- Are there order_items pointing to products or sellers that don't exist in the corresponding tables? 

SELECT COUNT (*) AS unmatched_products
FROM order_items oi 
LEFT JOIN products p ON oi.product_id = p.product_id 
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS unmatched_sellers
FROM order_items oi 
LEFT JOIN sellers s ON oi.seller_id = s.seller_id 
WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS unmatched_customers
FROM orders o 
LEFT JOIN customers c ON o.customer_id = c.customer_id 
WHERE c.customer_id IS NULL;



/*
The dataset initially covers Sep 2016 to Oct 2018, but several months are 
incomplete and therefore should be excluded from trend analysis:
  - Sep 2016:  4 orders   → platform just launching, not representative
  - Dec 2016:  1 order    → incomplete data
  - Nov 2016:  missing    → no data for this month
  - Sep 2018: 16 orders   → dataset cuts off mid-month
  - Oct 2018:  4 orders   → dataset cuts off mid-month

There is a spike in Nov 2017 to 7,544 orders — consistent with the seasonal 
effect of Black Friday, keep but annotate in visualisations.

RECOMMENDATION: Filter to Jan 2017 – Aug 2018 for clean trend analysis, 
as it gives 20 complete months with consistent, reliable order volumes.
*/
SELECT
	 DATE_TRUNC ('month', order_purchase_timestamp) AS rounded_to_month,
	 COUNT(*) AS order_count,
	 ROUND (SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC ('month', order_purchase_timestamp)) / SUM(COUNT(*))OVER () * 100, 2) AS cumulative_percentage
FROM orders o         
GROUP BY  DATE_TRUNC ('month', order_purchase_timestamp)
ORDER BY rounded_to_month
;
