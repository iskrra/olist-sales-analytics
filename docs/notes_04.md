# Day 4 — Customer Analytics & RFM Notes

## What I Did
Did a customer-level analysis including repeat purchase rate, RFM segmentation and a comprehensive customer report. 
RFM (Recency, Frequency, Monetary) is a standard framework used across retail, e-commerce, and consulting to segment customers by behaviour and value.

## Key Findings
- Total unique customers in the clean analysis window: 93096
- Repeat purchase rate: 3% — low repeat rates are common in marketplace e-commerce, but it also gives insight into how dependent the business is on constant new customer acquisition.
- Largest RFM segments: 'cannot lose them', 'new customer', 'needs attention' & 'champion'  with all of them having ~15% of customers
- At Risk and Lost segments together account for ~13% of the base
- The majority of top-100 customers by spend have first_order_date = last_order_date, confirming single-purchase behaviour even among high spenders
- Customers with multiple orders are rare but they are the core repeat buyers the RFM segmentation targets

## Decisions Made
- Used customer_unique_id and not customer_id to avoid counting the same customer multiple times
- Comprehensive customer report uses LEFT JOINs for reviews and categories so customers with no reviews or uncategorised purchases are still included rather than silently dropped
- DISTINCT ON used in the favourite_category CTE to efficiently pick the single highest-order-count category per customer without a subquery