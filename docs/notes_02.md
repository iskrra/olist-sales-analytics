# Day 2 — Revenue & Sales Analysis Notes

## What I Did
First round of business queries covering revenue trends, geographic breakdown, and payment behaviour. All revenue queries filter through the `delivered_orders` view for consistency.

## Key Findings
- Total revenue (Jan 2017–Aug 2018): R$13.18M
- Strongest month: Nov 2017 at ~R$1.15M — Black Friday spike
- Average month-over-month growth rate: ~14%
- Top 3 states by revenue: SP, RJ, MG (São Paulo's dominance bringing in ~40% of total revenue (expected given it's Brazil's most populous state))
- Credit card is the dominant payment method at ~75% of orders, averaging 3.5 installments (consistent with Brazilian consumer credit behaviour).

## Decisions Made
- Freight tracked separately from product revenue for a clearer view of what customers pay for goods vs. what goes to logistics.
- Payment analysis done on raw `order_payments` rather than `delivered_orders` since the payment method should not be affected by order status.
- November 2017 is excluded from the yearly average calculation in the performance comparison query — the Black Friday spike is roughly double a typical month and would make most months appear below average. The raw average is kept so the spike remains visible.
- Order value segmentation reveals that extra small orders (R$30–120) account for the largest share of order volume but largest share of the revenue comes from the smallest share of orders — extra large ones (>R$300).