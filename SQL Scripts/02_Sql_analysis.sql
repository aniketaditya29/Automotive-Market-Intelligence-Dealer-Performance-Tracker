-- ============================================================
-- QUERY 1: Business Overview — Headline KPIs
-- Question: What is the overall scale of the business?
-- ============================================================

SELECT
    COUNT(*)                                    AS total_transactions,
    SUM(units_sold)                             AS total_units_sold,
    ROUND(SUM(revenue) / 1000000000.0, 2)       AS total_revenue_bn,
    ROUND(AVG(unit_price) / 100000.0, 2)        AS avg_unit_price_lakhs,
    ROUND(AVG(customer_satisfaction_score), 2)  AS avg_satisfaction,
    MIN(date)                                   AS data_from,
    MAX(date)                                   AS data_to
FROM automobile_sales;

-- ============================================================
-- QUERY 2: Yearly Revenue Trend with YoY Growth %
-- Question: How has total revenue trended from 2020 to 2025?
-- ============================================================

SELECT
    year,
    SUM(units_sold)                                         AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)                   AS revenue_bn,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY year))
        / LAG(SUM(revenue)) OVER (ORDER BY year) * 100
    , 2)                                                    AS yoy_growth_pct
FROM automobile_sales
GROUP BY year
ORDER BY year;

-- ============================================================
-- QUERY 3: Revenue & Performance by Region
-- Question: Which regions drive the most revenue and volume?
-- ============================================================

SELECT
    region,
    COUNT(*)                                        AS total_transactions,
    SUM(units_sold)                                 AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)           AS revenue_bn,
    ROUND(AVG(unit_price) / 100000.0, 2)            AS avg_price_lakhs,
    ROUND(AVG(customer_satisfaction_score), 2)      AS avg_satisfaction,
    ROUND(SUM(revenue) * 100.0 
          / SUM(SUM(revenue)) OVER (), 2)           AS revenue_share_pct
FROM automobile_sales
GROUP BY region
ORDER BY revenue_bn DESC;

-- ============================================================
-- QUERY 4: Dealer Performance Ranking
-- Question: How do all 15 dealers rank across key metrics?
-- ============================================================

--Part A: Dealer Ranking
SELECT
    dealer,
    region,
    COUNT(*)                                        AS total_transactions,
    SUM(units_sold)                                 AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)           AS revenue_bn,
    ROUND(AVG(unit_price) / 100000.0, 2)            AS avg_price_lakhs,
    ROUND(AVG(customer_satisfaction_score), 2)      AS avg_satisfaction,
    ROUND(SUM(revenue) / SUM(units_sold) / 100000.0, 2) AS revenue_per_unit_lakhs,
    ROUND(SUM(revenue) * 100.0
          / SUM(SUM(revenue)) OVER (), 2)           AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(revenue) DESC)        AS revenue_rank
FROM automobile_sales
GROUP BY dealer, region
ORDER BY revenue_bn DESC;

--Part B: Dealer Tier Alotment
SELECT
    dealer,
    ROUND(SUM(revenue) / 1000000000.0, 2)       AS revenue_bn,
    ROUND(AVG(unit_price) / 100000.0, 2)         AS avg_price_lakhs,
    ROUND(AVG(customer_satisfaction_score), 2)   AS avg_satisfaction,
    CASE
        WHEN AVG(unit_price) >= 2500000 THEN 'Premium'
        WHEN AVG(unit_price) >= 1800000 THEN 'Mid-Range'
        ELSE                                 'Budget'
    END                                          AS dealer_tier
FROM automobile_sales
GROUP BY dealer
ORDER BY revenue_bn DESC;

--============================================================
-- QUERY 5: Revenue by Category and Fuel Type
-- Question: Which segments dominate and how is EV growing?
-- ============================================================

-- PART A: Revenue by Category
SELECT
    category,
    COUNT(*)                                        AS total_transactions,
    SUM(units_sold)                                 AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)           AS revenue_bn,
    ROUND(AVG(unit_price) / 100000.0, 2)            AS avg_price_lakhs,
    ROUND(AVG(customer_satisfaction_score), 2)      AS avg_satisfaction,
    ROUND(SUM(revenue) * 100.0
          / SUM(SUM(revenue)) OVER (), 2)           AS revenue_share_pct
FROM automobile_sales
GROUP BY category
ORDER BY revenue_bn DESC;

-- PART B: Revenue by Fuel Type across Years
SELECT
    year,
    fuel_type,
    SUM(units_sold)                                 AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)           AS revenue_bn,
    ROUND(SUM(units_sold) * 100.0
          / SUM(SUM(units_sold)) OVER (PARTITION BY year), 2) AS units_share_pct
FROM automobile_sales
GROUP BY year, fuel_type
ORDER BY year, revenue_bn DESC;

-- ============================================================
-- QUERY 6: Vehicle Model Pareto Analysis
-- Question: Which models drive 80% of total revenue?
-- ============================================================

-- PART A: Revenue per model with cumulative % 
WITH model_revenue AS (
    SELECT
        vehicle_model,
        category,
        SUM(units_sold)                             AS total_units,
        ROUND(SUM(revenue) / 1000000000.0, 2)       AS revenue_bn,
        ROUND(AVG(unit_price) / 100000.0, 2)        AS avg_price_lakhs,
        ROUND(AVG(customer_satisfaction_score), 2)  AS avg_satisfaction
    FROM automobile_sales
    GROUP BY vehicle_model, category
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY revenue_bn DESC)      AS revenue_rank,
        ROUND(revenue_bn * 100.0 
              / SUM(revenue_bn) OVER (), 2)         AS revenue_share_pct,
        ROUND(SUM(revenue_bn) OVER (
              ORDER BY revenue_bn DESC
              ROWS BETWEEN UNBOUNDED PRECEDING 
              AND CURRENT ROW) * 100.0
              / SUM(revenue_bn) OVER (), 2)         AS cumulative_pct
    FROM model_revenue
)
SELECT *
FROM ranked
ORDER BY revenue_rank;

-- PART B: The 80/20 answer -- how many models = 80% of revenue?
WITH model_revenue AS (
    SELECT
        vehicle_model,
        ROUND(SUM(revenue) / 1000000000.0, 2)       AS revenue_bn
    FROM automobile_sales
    GROUP BY vehicle_model
),
ranked AS (
    SELECT
        *,
        ROUND(SUM(revenue_bn) OVER (
              ORDER BY revenue_bn DESC
              ROWS BETWEEN UNBOUNDED PRECEDING
              AND CURRENT ROW) * 100.0
              / SUM(revenue_bn) OVER (), 2)         AS cumulative_pct
    FROM model_revenue
)
SELECT
    COUNT(*)                                        AS models_needed,
    ROUND(COUNT(*) * 100.0 / 47, 1)                AS pct_of_portfolio,
    MAX(cumulative_pct)                             AS revenue_covered_pct
FROM ranked
WHERE cumulative_pct <= 80;

-- ============================================================
-- QUERY 7: Customer Satisfaction vs Revenue Analysis
-- Question: Does higher satisfaction correlate with higher revenue?
-- ============================================================

-- PART A: Satisfaction vs Revenue by Dealer
WITH dealer_summary AS (
    SELECT
        dealer,
        region,
        ROUND(SUM(revenue) / 1000000000.0, 2)            AS revenue_bn,
        SUM(units_sold)                                  AS total_units,
        ROUND(AVG(customer_satisfaction_score), 2)       AS avg_satisfaction,
        ROUND(AVG(unit_price) / 100000.0, 2)             AS avg_price_lakhs
    FROM automobile_sales
    GROUP BY dealer, region
)
SELECT
    dealer,
    revenue_bn,
    avg_satisfaction,
    avg_price_lakhs,
    CASE
        WHEN avg_satisfaction >= 7.52 AND revenue_bn >= 6.0 THEN 'High Satisfaction, High Revenue'
        WHEN avg_satisfaction >= 7.52 AND revenue_bn <  6.0 THEN 'High Satisfaction, Low Revenue'
        WHEN avg_satisfaction <  7.52 AND revenue_bn >= 6.0 THEN 'Low Satisfaction, High Revenue'
        ELSE                                                     'Low Satisfaction, Low Revenue'
    END                                                  AS quadrant
FROM dealer_summary
ORDER BY avg_satisfaction DESC;

-- PART B: Satisfaction by Category
SELECT
    category,
    fuel_type,
    COUNT(*)                                        AS transactions,
    ROUND(AVG(customer_satisfaction_score), 2)      AS avg_satisfaction,
    ROUND(MIN(customer_satisfaction_score), 2)      AS min_satisfaction,
    ROUND(MAX(customer_satisfaction_score), 2)      AS max_satisfaction,
    ROUND(STDDEV(customer_satisfaction_score), 2)   AS std_deviation
FROM automobile_sales
GROUP BY category, fuel_type
ORDER BY avg_satisfaction DESC;

-- ============================================================
-- QUERY 8: Seasonal Trends — Monthly & Quarterly Patterns
-- Question: When does the business peak and trough?
-- ============================================================

-- PART A: Revenue and Units by Month
SELECT
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month')    AS month_name,
    COUNT(*)                                         AS total_transactions,
    SUM(units_sold)                                  AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)            AS revenue_bn,
    ROUND(AVG(revenue) / 1000000.0, 2)               AS avg_revenue_per_txn_mn,
    ROUND(AVG(customer_satisfaction_score), 2)       AS avg_satisfaction
FROM automobile_sales
GROUP BY month
ORDER BY month;

-- PART B: Revenue by Quarter
SELECT
    quarter,
    CASE quarter
        WHEN 1 THEN 'Q1 (Jan–Mar)'
        WHEN 2 THEN 'Q2 (Apr–Jun)'
        WHEN 3 THEN 'Q3 (Jul–Sep)'
        WHEN 4 THEN 'Q4 (Oct–Dec)'
    END                                              AS quarter_label,
    SUM(units_sold)                                  AS total_units,
    ROUND(SUM(revenue) / 1000000000.0, 2)            AS revenue_bn,
    ROUND(SUM(revenue) * 100.0
          / SUM(SUM(revenue)) OVER (), 2)            AS revenue_share_pct
FROM automobile_sales
GROUP BY quarter
ORDER BY quarter;

-- PART C: Monthly Revenue Heatmap data
SELECT
    year,
    month,
    TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Mon')       AS month_name,
    ROUND(SUM(revenue) / 1000000000.0, 2)            AS revenue_bn,
    SUM(units_sold)                                  AS total_units
FROM automobile_sales
GROUP BY year, month
ORDER BY year, month;