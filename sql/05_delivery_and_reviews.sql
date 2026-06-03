/*
DELIVERY PERFORMANCE & CUSTOMER SATISFACTION
Answers: What share of orders arrive on time? Does late delivery harm satisfaction scores? 
Which categories combine poor delivery & reviews? Are delivery & satisfaction improving over time?

KPIs: On-Time Delivery Rate, Avg Delivery Days, Category Delivery-Satisfaction Correlation,
NPS-style Segmentation, Monthly Delivery Trend, Monthly Satisfaction Trend.

-- Key insight: delivery performance is a primary but not sole driver of customer satisfaction 
-- some categories show poor reviews despite strong on-time rates, so product quality also plays a role.
*/


-- 1. OVERALL DELIVERY PERFORMANCE
-- Classifies each order as on time or late, then summarises.
-- Positive = delivered early, negative = delivered late.

WITH delivery_measures AS (
	SELECT 
		order_id,
		ROUND((EXTRACT(EPOCH FROM(order_estimated_delivery_date - order_delivered_customer_date)) / 86400), 1)	AS days_early_late,
		ROUND((EXTRACT(EPOCH FROM(order_delivered_customer_date - order_purchase_timestamp)) / 86400), 1)		AS actual_days,
		CASE 
			WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on time'
			ELSE 'late'
		END		AS delivery_status
	FROM delivered_orders t 
)
SELECT
	delivery_status,
	COUNT(*)											AS order_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)	AS pct_of_orders,
	ROUND(AVG(days_early_late), 1)						AS avg_days_early_late,
	ROUND(AVG(actual_days), 1)							AS avg_actual_days	
FROM delivery_measures
GROUP BY delivery_status
;



-- 2. DELIVERY STATUS VS REVIEW SCORE
-- Connects delivery efficiency performance to customer satisfaction.
-- The gap in avg_review between on-time and late orders is the core finding 
-- delivery reliability directly affects how customers rate their experience.

WITH delivery_measures AS (
	SELECT 
		t.order_id,
		r.review_score,
		ROUND((EXTRACT(EPOCH FROM(order_estimated_delivery_date - order_delivered_customer_date)) / 86400), 1)	AS days_early_late,
		ROUND((EXTRACT(EPOCH FROM(order_delivered_customer_date - order_purchase_timestamp)) / 86400), 1)		AS actual_days,
		CASE 
			WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on time'
			ELSE 'late'
		END		AS delivery_status
	FROM delivered_orders t 
	JOIN order_reviews r ON r.order_id = t.order_id
)
SELECT
	delivery_status,
	COUNT(*)										AS review_count,
	ROUND(AVG(review_score), 2)						AS avg_review,
	COUNT(CASE WHEN review_score >= 4 THEN 1 END)	AS good_reviews,
	COUNT(CASE WHEN review_score <= 2 THEN 1 END)	AS bad_reviews,
	ROUND(COUNT(CASE WHEN review_score >= 4 THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_good_reviews
FROM delivery_measures
GROUP BY delivery_status
;



-- 3. CATEGORY-LEVEL ON-TIME RATE & REVIEW CORRELATION
-- Five-table JOIN: delivered_orders → order_reviews → order_items → products → category_translation.
-- Shows on-time delivery rate and average review score per category to identify
-- which ones underperform on both dimensions.
-- Filtered with HAVING to ensure the results are statistically meaningful.
-- Ordered by pct_on_time ASC to surface worst-performing categories first.
-- Key finding: some categories with high on-time rates sstill score poorly on reviews (like diapers, 
-- office furniture), suggesting product quality/condition drives dissatisfaction independently.

SELECT 
	ct.product_category_name_english,
	ROUND(COUNT(CASE WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 1 END) * 100.0 / COUNT(*), 1)	AS pct_on_time,
	COUNT(*)																	AS review_count,
	ROUND(AVG(review_score), 2)													AS avg_review,
	COUNT(CASE WHEN review_score <= 2 THEN 1 END)								AS bad_reviews,
	ROUND(COUNT(CASE WHEN review_score <= 2 THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_bad_reviews
FROM delivered_orders t 
JOIN order_reviews r ON r.order_id = t.order_id
JOIN order_items oi ON oi.order_id = t.order_id 
JOIN products p ON p.product_id = oi.product_id 
JOIN category_translation ct ON ct.product_category_name = p.product_category_name 
GROUP BY ct.product_category_name_english 
HAVING COUNT(*) >= 30
ORDER BY pct_on_time ASC
;



-- 4. ON-TIME DELIVERY RATE TREND BY MONTH
-- Tracks whether operational performance improves or deteriorates over time as order volume grows.
-- avg_days_early_late: average days between estimated and actual delivery
-- per month — positive = delivered early on average, higher = more buffer.

SELECT 
	DATE_TRUNC('month',t.order_purchase_timestamp)::date	AS MONTH,
	COUNT(*)												AS total_orders, 	
	COUNT(CASE WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 1 END)								AS orders_on_time,
	ROUND(COUNT(CASE WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 1 END) * 100.0 / COUNT(*), 1)	AS pct_on_time,
	ROUND(AVG(EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_delivered_customer_date)) / 86400), 1) 				AS avg_days_early_late
FROM delivered_orders t 
GROUP BY DATE_TRUNC('month',t.order_purchase_timestamp)::date
ORDER BY MONTH ASC
;



-- 5. NPS-STYLE REVIEW SEGMENTATION
-- Measures how likely a customer is to recommend a company's product or service
-- Promoters are customers that are satisfied and are likely to recommend, 
-- Passives are neutral & Detractors are dissatisfied.
-- NPS score = % Promoters - % Detractors and gives a single score for the platform.
-- Interpretation: above 50 = excellent, 0–50 = good, below 0 = problem.


WITH customer_segmentation  AS (
	SELECT 
		CASE
			WHEN review_score = 5		THEN '1. promoter'
			WHEN review_score IN (4, 3)	THEN '2. passive'
			ELSE							 '3. detractor'
		END			AS customer_segment, 
		COUNT(*)	AS review_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)  AS pct_of_reviews
	FROM order_reviews r
	JOIN delivered_orders t ON r.order_id = t.order_id 
	GROUP BY customer_segment
),
nps_score AS (
	SELECT 	
		'NPS score'			AS customer_segment,
		NULL::bigint		AS review_count,
		ROUND(MAX(CASE WHEN customer_segment LIKE '%promoter%' THEN pct_of_reviews END) - 
		MAX(CASE WHEN customer_segment LIKE '%detractor%' THEN pct_of_reviews END), 2)	AS pct_of_reviews
	FROM customer_segmentation
)
SELECT * FROM customer_segmentation
UNION ALL
SELECT * FROM nps_score
ORDER BY customer_segment
;
