
/*
DATA SCOPE NOTES — Read before running any time-series analysis
---------------------------------------------------------------
The dataset initialy covers Sep 2016 to Oct 2018, but several months are 
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
	 ROUND (SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC ('month', order_purchase_timestamp)) / SUM(COUNT(*))OVER () * 100, 2) AS cumulative_percantage
FROM delivered_orders t        
GROUP BY  DATE_TRUNC ('month', order_purchase_timestamp)
ORDER BY rounded_to_month
;
