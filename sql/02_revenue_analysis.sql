/*
REVENUE & SALES ANALYSIS
Answers: How is revenue trending over time? Which markets drive the most value? 
How do customers prefer to pay?

KPIs: Monthly Revenue, Average Order Value, Month-over-Month Growth Rate,
Revenue by State, Payment Method Mix.
*/

-- 1. MONTHLY REVENUE TREND
-- Delivered orders only to avoid revenue distortion.
-- The price data from order_items is joined onto the delivered orders.
-- Revenue shown as a total and broken down to the components for easier 
-- interpretation of product revenue/shipping cost/total customer spent.
SELECT 	
	DATE_TRUNC('month', t.order_purchase_timestamp)::date AS month,
	COUNT(DISTINCT t.order_id)							AS order_quantity,
	ROUND(SUM(oi.price),2)								AS product_revenue,
	ROUND(SUM(oi.freight_value),2)						AS freight_revenue,
	ROUND(SUM(oi.price+oi.freight_value),2) 			AS total_revenue,
	ROUND(AVG(oi.price), 2) 							AS avg_product_value, 
	ROUND(SUM(oi.price) / COUNT(DISTINCT t.order_id), 2) AS avg_order_value
FROM delivered_orders t 
JOIN order_items oi  ON t.order_id=oi.order_id 
GROUP BY DATE_TRUNC('month', t.order_purchase_timestamp)
ORDER BY month ASC
;


-- 2. MONTHLY REVENUE GROWTH RATE
-- Gives insight into wether the business is accelerating or slowing down
-- With the LAG() we can calculate the % change when comparing to the previous month
-- The negative values indicate a decline in revenue when compared to before, 
-- and NULL appears for the first month since there is no prior month.
WITH monthly_revenue AS (
	SELECT 
		DATE_TRUNC('month', t.order_purchase_timestamp)::date AS month,
		ROUND(SUM(oi.price),2)								AS revenue
	FROM delivered_orders t 
	JOIN order_items oi ON t.order_id = oi.order_id 
	GROUP BY DATE_TRUNC('month', t.order_purchase_timestamp)::date
	ORDER BY MONTH ASC)
SELECT 
	MONTH, 
	revenue,
	LAG(revenue,1) OVER (ORDER BY MONTH ASC) AS prev_month_revenue,
	ROUND((revenue - LAG(revenue,1) OVER (ORDER BY MONTH ASC)) / LAG(revenue,1) OVER (ORDER BY MONTH ASC) * 100, 2) AS monthly_growth_pct
FROM monthly_revenue
ORDER BY MONTH ASC
;


-- 3. REVENUE BY STATE
-- Shows us which regions drive the most business — essential for further 
-- geographic expansion, logistics prioritisation or region based marketing.
-- Avg order value used as it's generally a better KPI (compared to avg product value) 
SELECT 
	c.customer_state											AS state,
	COUNT(DISTINCT t.customer_id)								AS unique_customers,
	ROUND(SUM(oi.price) / COUNT(DISTINCT t.order_id), 2) 		AS avg_order_value,
	ROUND(SUM(oi.price),2)										AS revenue,
	ROUND((SUM(oi.price) / SUM(SUM(oi.price)) OVER ()) * 100, 2)AS pct_of_total_revenue
FROM delivered_orders t 
JOIN customers c ON c.customer_id = t.customer_id 
JOIN order_items oi ON oi.order_id = t.order_id 
GROUP BY c.customer_state
ORDER BY revenue DESC
;


-- 4. PAYMENT METHOD BREAKDOWN
-- Looking into installment data, because of it's importance for cash flow analysis.
-- Gives insight into the quantity of payments for each payment type so that subsewuentualy
-- campaignes can be implemeted to promote the use one over the others if theres a need for it.
SELECT 
	op.payment_type,
	ROUND(AVG(op.payment_installments),1)	AS avg_installments,
	ROUND(AVG(op.payment_value),2)			AS avg_payment_value,
	COUNT(DISTINCT op.order_id) 			AS order_quantity,
	ROUND(SUM(op.payment_value),2) 			AS total_payment_value,
	ROUND((COUNT(DISTINCT op.order_id) / SUM(COUNT(DISTINCT op.order_id)) OVER() * 100.0), 2) AS pct_of_orders
FROM order_payments op 
GROUP BY op.payment_type 
ORDER BY order_quantity  DESC
;


-- 5. REVENUE COMPARISON
-- Shows how revenue accumulates through each year, month by month.
-- Used payment_value (actual customer spend) rather than product price, which includes 
-- vouchers and captures the full cash amount received.
-- Second CTE used to compute the calculations in the place of repeating the full expression.
-- Average excludes November 2017 to prevent the Black Friday spike from skewing the yearly baseline
-- 2017 shows a more or less steady growth trend with above-average months from May onward.
-- 2018 comparison is less conclusive given only 8 months of data are available.

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', t.order_purchase_timestamp)::date AS month,
        EXTRACT('year' FROM t.order_purchase_timestamp)::int  AS year,
        ROUND(SUM(op.payment_value), 2)						  AS revenue
    FROM delivered_orders t
    JOIN order_payments op ON op.order_id = t.order_id
    GROUP BY
        DATE_TRUNC('month', t.order_purchase_timestamp),
        EXTRACT('year' FROM t.order_purchase_timestamp)
),
with_comparisons AS (
    SELECT
        month,
        year,
        revenue,
        ROUND(AVG(revenue) OVER (PARTITION BY year), 2)                      AS avg_monthly_revenue,
        ROUND(AVG(revenue) FILTER (
            WHERE NOT (year = 2017 AND EXTRACT('month' FROM month) = 11)
        ) OVER (PARTITION BY year), 2)                                       AS avg_without_nov17,
        ROUND(revenue - AVG(revenue) FILTER (
            WHERE NOT (year = 2017 AND EXTRACT('month' FROM month) = 11)
        ) OVER (PARTITION BY year), 2)                                       AS diff_to_adj_avg,
        ROUND(SUM(revenue) OVER (PARTITION BY year ORDER BY month), 2)       AS cumulative_revenue_ytd
    FROM monthly
)
SELECT
    month,
    revenue,
    avg_monthly_revenue,
    avg_without_nov17,
    diff_to_adj_avg,
    CASE
        WHEN diff_to_adj_avg > 0 THEN 'above average'
        WHEN diff_to_adj_avg = 0 THEN 'average'
        ELSE 'below average'
    END	AS vs_adjusted_avg,
    cumulative_revenue_ytd
FROM with_comparisons
ORDER BY MONTH
;


-- 6. ORDER VALUE SEGMENTATION
-- Data Segmentation + Part-to-Whole
-- Breaks down orders into value based categories to better understand the revenue mix.
-- A business dominated by small orders has different logistics and margin implications 
-- when compared to one driven by large orders.

WITH order_values AS (
	SELECT 
		oi.order_id,
		SUM (oi.price) AS order_value
	FROM delivered_orders t   
	JOIN order_items oi ON oi.order_id = t.order_id 
	GROUP BY oi.order_id 
)
SELECT 
	CASE 
		WHEN order_value < 30 THEN 'extra small'
		WHEN order_value < 120 THEN 'small'
		WHEN order_value < 210 THEN 'medium'
		WHEN order_value < 300 THEN 'large'
		ELSE 'extra large'
	END 													AS order_segment,
	ROUND(AVG(order_value), 2) 								AS avg_order_value,
	COUNT (*)												AS order_count, 
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) 		AS pct_of_orders,
	ROUND(SUM(order_value), 2)								AS total_revenue,
	ROUND(SUM(order_value) * 100.0 / SUM(SUM(order_value)) OVER(), 2) AS pct_of_revenue
FROM order_values 
GROUP BY order_segment
ORDER BY order_count DESC
;