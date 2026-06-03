# Day 1 — Data Exploration Notes

## What I Did
Before doing ting any real analysis, I used this day for getting familiar with the dataset — checking row counts, understanding the date range, finding data quality issues, and figuring out which portion of the data is actually clean  enough to analyse. As not to build analysis on top of misunderstood data.

## What the Data Looks Like
The dataset contains 9 tables covering orders, customers, products, sellers, payments, and reviews from the Olist Brazilian e-commerce platform. Row counts match the Kaggle documentation (successful import).

The dataset nominally runs from September 2016 to October 2018, but several months are clearly incomplete or are entirely lacking. 
The clean, consistent window for time-series analysis is January 2017 through August 2018 —> 20 complete months.

Notable pattern: November 2017 shows a spike to 7544 orders (Black Friday seasonal demand and represents genuine business activity).

## Data Quality Findings
No meaningful orphaned records were found — products, sellers, and customers referenced in orders all exist in their respective tables. Missing delivery timestamps are concentrated in non-delivered orders (cancelled, unavailable). Delivered orders dominate the dataset at around 97% of all orders.

The order_reviews table had import issues due to special characters and newlines inside customer comment fields — resolved by using PostgreSQL's COPY command with explicit quote handling rather than DBeaver's CSV importer.

## Decisions Made
- By using the `delivered_orders` view created in `00_views_and_setup.sql`, all revenue and time-series analysis will be filtered to delivered orders only, within the Jan 2017 – Aug 2018 timeframe, all in order to avoid data distortion.
- The November 2017 Black Friday spike will be kept in trend analysis but   flagged with an annotation in Power BI.