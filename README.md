# Olist E-Commerce Sales Analytics

End-to-end analytics project exploring sales performance, customer behaviour, and operational quality 
of a Brazilian e-commerce marketplace — from raw relational data in PostgreSQL to a Power BI dashboard.

---

## Project Background

Olist is a Brazilian e-commerce platform connecting smaller sellers to major marketplaces. 
This project analyses ~93,000 delivered orders across 20 months (Jan 2017 – Aug 2018), covering revenue trends, 
product and seller performance, customer segmentation and the delivery speed - customer satisfaction relationship.

It was built to demonstrate end-to-end analytical capability: understanding raw relational data, writing 
multi-table SQL to answer real business questions and presenting the findings in a Power BI dashboard.

---

## Tools Used

- PostgreSQL — data storage, transformation and analysis
- DBeaver — database management and query testing
- VS Code & Git — version control and file management
- Power BI — dashboard and visualisation

---

## Dataset

Source: [Olist Brazilian E-Commerce — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
Size: ~100,000 orders across 9 relational tables  
Full data time span: September 2016 – October 2018  
Clean analysis window: January 2017 – August 2018 (incomplete/missing months were excluded)

| Table                | Description                                     |
|-....................-|-...............................................-|
| orders               | A row per order with timestamps and status      |
| order_items          | A row per item ordered (price, seller, product) |
| order_payments       | Payment method and amount per order             |
| order_reviews        | Customer reviews as a score and comment         |
| customers            | Customer location and identifier                |     
| products             | Real life product dimensions and category       |
| sellers              | Seller location                                 |
| category_translation | Portuguese to English category name translation |
| geolocation          | Zip code coordinate data                        |

---

## Business Questions Answered

**Revenue & Growth**
- What are the monthly revenue trend and month-over-month growth rate?
- Which Brazilian states generate the most revenue?
- How do customers prefer to pay and what is the average installment usage?
- How does revenue compare year-over-year across overlapping months?

**Product & Seller Performance**
- Which product categories drive the most revenue?
- How do sellers compare across revenue, review scores, and delivery speed?
- How concentrated is revenue across the seller base?
- Which categories over- or under-perform relative to the platform average?

**Customer Analytics**
- What is the repeat purchase rate?
- How can customers be segmented using the RFM framework?
- What does a full customer profile look like when spending, category preference, 
satisfaction, and segment are combined?

**Operational Quality**
- What percentage of orders arrive on time versus late?
- Do late deliveries receive measurably lower review scores?
- Which categories have the worst delivery satisfaction?
- Is delivery performance improving or declining over time?
- How does the platform score on an NPS-style sentiment framework?

---

## Key Findings

1. Revenue grew at ~14% month-over-month across the analysis window, reaching R$13.18M total. 
November 2017 shows a Black Friday spike to ~R$1.15M roughly double a typical month, and it distorts 
yearly averages and is treated as an outlier in comparative analysis.

2. São Paulo dominates geographically accounting for ~40% of total revenue.
The top 3 states (SP, RJ, MG) together represent the majority of the business.
Credit card is the dominant payment method at ~75% of orders, with an average of 3.5 installments,
and it isn't surprising as it is consistent with Brazilian consumer credit culture.

3. Health & Beauty is the top revenue-generating category at R$1.23M (~9.5% of total). 
The top 3 categories account for ~26% of total revenue.
The seller base is well-diversified — the top 10 sellers generate only ~13% of revenue, 
with no single seller posing meaningful concentration risk.

4. Late deliveries receive an average review score of 2.6 versus 4.3 for on-time orders — confirming delivery 
that reliability is a primary satisfaction driver. 
However, in spite of this several categories break this pattern: diapers (97.2% on-time, 3.33 avg review) 
along with office furniture (91.1% on-time, 3.52 avg review) score poorly despite strong delivery. 
This suggests that the product quality or condition on arrival drives dissatisfaction independently.

5. The repeat purchase rate is just 3%, meaning the vast majority of customers buy only once. 
RFM (recency, drequency, monetary) segmentation is therefore dominated by recency and monetary dimensions.

6. The platform NPS score (how likely a customer is to recommend the company) is ~46 in the "good" range (0–50).
With 59% Promoters, 28% Passives and 12% Detractors the score is good but with meaningful room for improvement, 
particularly in categories where satisfaction lags delivery performance.

---

## SQL Files

| File                                                                 | Description |
|-....................................................................-|-................-|
| [00_views_and_setup.sql](sql/00_views_and_setup.sql)                 | Base view filtering to clean delivered orders (Jan 2017–Aug 2018) |
| [01_data_exploration.sql](sql/01_data_exploration.sql)               | Row counts, date range, data quality checks, monthly distribution |
| [02_revenue_analysis.sql](sql/02_revenue_analysis.sql)               | Monthly trend, MoM growth, YoY comparison, state breakdown, payment mix, order value segmentation |
| [03_product_seller_analysis.sql](sql/03_product_seller_analysis.sql) | Category revenue, product report, seller scorecard, concentration risk, category benchmark |
| [04_customer_analysis.sql](sql/04_customer_analysis.sql)             | Customer summary, repeat rate, RFM segmentation, comprehensive customer report |
| [05_delivery_reviews.sql](sql/05_delivery_reviews.sql)               | Delivery performance, delivery vs satisfaction, category correlation, monthly trend, NPS segmentation |

---

## Dashboard

*Screenshots will be added after Power BI build*

---

## Data Notes

- November 2016 is absent from the dataset with no clear explanation
- order_reviews contains some duplicate review_id values — treated as separate review submissions in aggregations
- A small number of order_items rows reference products with no entry in the products table 
is treated as negligible and excluded from category-level analysis.
- The same real customer can appear with multiple customer_id values across different orders
for this reason customer_unique_id is used throughout the customer-level analysis.
- Category-level queries involving order_items are weighted by item count per order rather than order count, 
due to the multi-table JOIN structure.