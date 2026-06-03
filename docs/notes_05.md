# Day 5 — Delivery Performance & Customer Satisfaction Notes

## What I Did
Analysed the relationship between delivery performance and customer satisfaction across five queries: overall delivery performance, delivery status vs review scores, category-level correlation, monthly delivery trend, and NPS-style review segmentation.
The main question was whether delivery reliability directly drives customer satisfaction — and the answer turned out to be more nuanced than expected.

## Key Findings
- On-time delivery rate: 92% of orders arrived on or before the estimated date
- Average duration for delivery for on-time orders is ~11 days vs 31.5 days for late orders
- Late deliveries receive an average review score of 2.6 vs 4.3 for on-time orders, confirming delivery reliability is a primary satisfaction driver for most categories.
- Some categories break the delivery-satisfaction pattern: diapers (97.2% on-time (highest in dataset) but avg review 3.33 (lowest in dataset)) and office furniture (91.1% on-time, 3.52 avg review) and this suggests that the dissatisfaction is likely driven by product quality, condition on arrival, or unmet price expectations — not solely delivery timing.
- Early 2017 had very conservative delivery estimates (~27 days buffer), which inflated on-time rates — as estimates tightened (to ~10-12 days through 2017-2018), performance became more volatile.
- Black Friday strained logistics capacity so in November 2017 on-time rate dropped to ~86%; March 2018 was the worst month at ~79% on-time with only 5.7 days average buffer & then June 2018 being the best month at almost 99% on-time rate — strong recovery
- NPS-style segmentation: ~60% Promoters, ~28% Passives, ~12% Detractors
- Pseudo-NPS score: ~46 —  falls in the "good" range (0–50) but can be improved upon

## Decisions Made
- Monthly trend runs on delivered_orders directly without further JOINs as to keep it lightweight and fast
- `days_early_late` = estimated minus delivered: positive = early, negative = late
- HAVING threshold set at 30 reviews for category analysis to ensure statistical meaningfulness without being overly restrictive
- NPS segmentation uses UNION ALL to append the calculated score as a row rather than as a separate query, keeping the output self-contained
- Detractors defined as 1&2 stars rather than just 1 to align with standard NPS methodology adapted for a 5-point scale

## Interesting Observations
- What specifically drives dissatisfaction in diapers and office furniture if not delivery? Product damage in transit is a plausible hypothesis for furniture; for diapers it may be price sensitivity or substitution effects
- Does the March 2018 on-time rate drop correlate with a review score drop that month? 
- Categories underperforming on both delivery and reviews are highest-priority improvement targets — cross-reference with `04_product_seller_analysis.sql`