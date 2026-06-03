-- 1. TOP PRODUCT CATEGORIES BY REVENUE
-- Insight into the revenue breakdown by product categories, as to see
-- the biggest revenue drivers.
-- The translations table sole purpose is to give back English instead 
-- of Portuguese category names - use case for a dimension/lookup table.
SELECT
	ct.product_category_name_english,
	COUNT(DISTINCT oi.order_id)								AS order_quantity,
	ROUND(AVG(oi.price), 2) 								AS avg_item_price,
	ROUND(SUM(oi.price)*100.0 / SUM(SUM(oi.price)) OVER(), 2)AS pct_of_revenue,
	ROUND(SUM(oi.price),2)									AS product_revenue,
	ROUND(SUM(oi.freight_value),2)							AS freight_revenue,
	ROUND(SUM(oi.price+oi.freight_value),2) 				AS total_revenue
FROM order_items oi 	
JOIN products p ON oi.product_id = p.product_id 
JOIN category_translation ct  ON ct.product_category_name = p.product_category_name 
WHERE oi.order_id IN (SELECT order_id FROM delivered_orders t)
GROUP BY ct.product_category_name_english
ORDER BY pct_of_revenue DESC
;



-- 2. TOP PRODUCTS BY VOLUME
-- Gives  a clearer picture of the top performing products and their basic metrics.
-- Categories are included to give each product business context, and to make an 
-- easier connection to the top product categories.

SELECT 
	oi.product_id,
	ct.product_category_name_english,
	COUNT(oi.order_id) 	AS total_orders,
	ROUND(SUM(oi.price), 2) AS total_revenue,
	ROUND(AVG(oi.price), 2) AS avg_price,
	ROUND(COUNT(oi.order_id) * 100.0 / SUM(COUNT(oi.order_id)) OVER (), 3) AS pct_of_all_orders
FROM delivered_orders t 
JOIN order_items oi ON oi.order_id = t.order_id 
JOIN products p ON oi.product_id = p.product_id 
JOIN category_translation ct ON ct.product_category_name = p.product_category_name 
GROUP BY oi.product_id, ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 100
;



-- 3. SELLER PERFORMANCE SCORECARD
-- Combines revenue, customer satisfaction and delivery speed into one view  
-- for an easier assessment of seller quality. 
-- A CTE is used to avoid any distortion that multi-item orders may cause.
-- Only sellers with 30+ fulfilled orders are included, as to avoid the results 
-- being skewed by lower-volume sellers.
-- EXTRACT(EPOCH FROM interval) converts the time difference between the timestamps 
-- into seconds dividing by 86400 converts seconds to days.
-- avg_days_difference: negative -> delivered ahead of schedule, positive -> late.
WITH seller_order AS (
	SELECT 
		oi.seller_id,
		oi.order_id,
		SUM(oi.price)						AS order_revenue,
		AVG(r.review_score)					AS review_score,
		MAX(t.order_purchase_timestamp)		AS purchase_date,
        MAX(t.order_delivered_customer_date)AS delivered_date,
        MAX(t.order_estimated_delivery_date)AS estimated_date
	FROM order_items oi 
	JOIN delivered_orders t ON oi.order_id = t.order_id 
	LEFT JOIN order_reviews r ON oi.order_id = r.order_id 
	GROUP BY oi.seller_id, oi.order_id 
)
SELECT
	s.seller_id,
	s.seller_state,
	COUNT(so.order_id)				AS orders_fulfilled,
	ROUND(SUM(so.order_revenue), 2)	AS revenue,
	ROUND(AVG(so.review_score), 2) 	AS avg_review_score,
	ROUND(AVG(EXTRACT(EPOCH FROM(so.delivered_date - so.purchase_date)) / 86400), 2)	AS avg_delivery_days,
	ROUND(AVG(EXTRACT(EPOCH FROM(so.estimated_date - so.purchase_date)) / 86400), 2) 	AS avg_estimated_days,
	ROUND((AVG(EXTRACT(EPOCH FROM(so.delivered_date - so.purchase_date)) / 86400))
			- AVG(EXTRACT(EPOCH FROM(so.estimated_date - so.purchase_date)) / 86400), 2)AS avg_days_difference
FROM sellers s
JOIN seller_order so ON s.seller_id = so.seller_id 
GROUP BY s.seller_id, s.seller_state 
HAVING COUNT(so.order_id)>=30
ORDER BY orders_fulfilled DESC
LIMIT 50
;


-- 4. SELLER CONCENTRATION RISK
-- Shows what percentage of total revenue comes from the top sellers. This is important to have in mind because 
-- if a small number of sellers generate most of the revenue, the company is more vulnerable - the actions of 
-- the top sellers have a disproportionately large impact on the overall performance.
-- The cumulative_pct column shows the running total as you move down the ranked list.
-- There's no need to filter based on the fullfiled orders because of the ranking.
WITH seller_revenue AS (
	SELECT 
		oi.seller_id,
		ROUND(SUM(oi.price),2)									 AS revenue,
		ROUND(SUM(oi.price)*100.0 / SUM(SUM(oi.price)) OVER(), 2)AS pct_of_revenue
	FROM sellers s 
	JOIN order_items oi ON oi.seller_id = s.seller_id 
	WHERE oi.order_id IN (SELECT order_id FROM delivered_orders t)
	GROUP BY oi.seller_id 
	ORDER BY pct_of_revenue DESC
	),
ranked AS (
	SELECT
		seller_id,
		revenue, 
		pct_of_revenue,
		RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
	FROM seller_revenue 
	)
SELECT
	*,
	ROUND((SUM(revenue) OVER(ORDER BY revenue_rank) / SUM(revenue) OVER ()) * 100.0, 2) AS cum_revenue_pct
FROM ranked  
WHERE revenue_rank<=150
;


-- 5. CATEGORY PERFORMANCE VS PLATFORM AVERAGE
-- Benchmarks each category against the overall platform average for both review score and delivery speed. 
-- More useful than a simple ranking because it immediately shows which categories are benefiting and 
-- which ones are dragging the platform down and by how much.
-- Only the categories  with more than 30 completed orders are taken into account to ensure the integrity
-- of the analysis.

WITH metrics AS ( 
	SELECT 
		ct.product_category_name_english AS category,
		COUNT(DISTINCT oi.order_id)		 AS order_count,
		ROUND(AVG(r.review_score), 2) 	 AS avg_review_score,
		ROUND(AVG(
			EXTRACT(EPOCH FROM(
			t.order_delivered_customer_date  - t.order_purchase_timestamp)) 
			/ 86400), 2)  				 AS avg_delivery_days,
		ROUND(SUM(oi.price), 2)			 AS revenue
	FROM delivered_orders t 
	JOIN order_items oi ON oi.order_id = t.order_id 
	JOIN products p ON oi.product_id = p.product_id 
	JOIN category_translation ct ON ct.product_category_name = p.product_category_name 
	LEFT JOIN order_reviews r ON r.order_id = t.order_id 
	GROUP BY ct.product_category_name_english
	HAVING 	COUNT(DISTINCT oi.order_id) >= 30
)
SELECT 
	category,
	order_count, 
	avg_review_score, 
	ROUND(AVG(avg_review_score) OVER(), 2) 						AS avg_total_review,
	ROUND(avg_review_score - AVG(avg_review_score) OVER (), 2)  AS diff_to_total_review,
	CASE
		WHEN avg_review_score - AVG(avg_review_score) OVER () > 0 THEN 'above average'
		WHEN avg_review_score - AVG(avg_review_score) OVER () < 0 THEN 'below average'
		ELSE 'average'
	END		AS reviews_vs_platform,
	avg_delivery_days,
	ROUND(AVG(avg_delivery_days) OVER(), 2) 					 AS avg_total_days,
	ROUND(avg_delivery_days - AVG(avg_delivery_days) OVER (), 2) AS diff_to_total_days,
	CASE
		WHEN avg_delivery_days - AVG(avg_delivery_days) OVER () > 0 THEN 'slower than average'
		WHEN avg_delivery_days - AVG(avg_delivery_days) OVER () < 0 THEN 'faster than average'
		ELSE 'average'
	END		AS speed_vs_platform
FROM metrics
ORDER BY revenue DESC
;