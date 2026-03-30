-- Module 6 → Sector Performance Analysis

USE stock_analysis;
SELECT * FROM stocks;
SELECT * FROM companies;

-- Query 1 — Average Closing Price per Sector

SELECT
c.sector,
ROUND(AVG(s.close),2) as avg_closing_price
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector
ORDER BY avg_closing_price DESC

-- Query 2 — Sector wise Total & Average Volume

SELECT
c.sector,
SUM(s.volume) as total_volume,
ROUND(AVG(s.volume)) as avg_volume
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector
ORDER BY c.sector

-- Query 3 — Sector wise Price Growth Over 5 Years


WITH t as (SELECT
ticker,
FIRST_VALUE (close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
last_value(close) OVER (PARTITION BY ticker ORDER BY date 
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks)

SELECT
c.sector,
ROUND(AVG(first_close),2) as avg_starting_price,
ROUND(AVG(last_close),2) as avg_ending_price,
ROUND(AVG(((last_close-first_close)/first_close))*100,2) as avg_growth_rate
FROM t
JOIN companies c ON t.ticker = c.ticker
GROUP BY c.sector
ORDER BY avg_growth_rate DESC;

-- Query 4 — Yearly Sector Performance Trend

SELECT
c.sector,
year(s.date) as year,
ROUND(AVG(s.close),2) as avg_price,
RANK() OVER (PARTITION BY year(s.date) ORDER BY ROUND(AVG(s.close),2) DESC) as sector_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector, year
ORDER BY year;

-- Query 5 — Best & Worst Performing Stock per Sector
 
WITH t as (SELECT 
ticker,
FIRST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
LAST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks),

r as (SELECT 
c.sector,
t.ticker,
ROUND(((last_close-first_close)/first_close)*100, 2) as gain_pct,
RANK() OVER (PARTITION BY c.sector ORDER BY ROUND(((last_close-first_close)/first_close)*100, 2) DESC) as ticker_rank,
COUNT(*) over (PARTITION BY c.sector) as last_rank
FROM t
JOIN companies c ON t.ticker = c.ticker
GROUP BY c.sector, t.ticker, last_close, first_close)

SELECT 
sector,
MAX(CASE WHEN ticker_rank = 1 THEN ticker END) as best_stock,
MAX(CASE WHEN ticker_rank = 1 THEN gain_pct END) as best_gain_pct,
MAX(CASE WHEN ticker_rank = last_rank THEN ticker END) as worst_stock,
MAX(CASE WHEN ticker_rank = last_rank THEN gain_pct END) as worst_gain_pct
FROM r
GROUP BY sector
ORDER BY best_gain_pct DESC;

-- OR
-- (Without using MAX function as a seperator)

WITH t AS (
    SELECT DISTINCT
        ticker,
        FIRST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date) AS first_close,
        LAST_VALUE(close) OVER (
            PARTITION BY ticker ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_close
    FROM stocks
),

r AS (
    SELECT 
        c.sector,
        t.ticker,
        ROUND(((last_close - first_close) / first_close) * 100, 2) AS gain_pct,
        ROW_NUMBER() OVER (
            PARTITION BY c.sector 
            ORDER BY ((last_close - first_close) / first_close) DESC
        ) AS best_rank,
        ROW_NUMBER() OVER (
            PARTITION BY c.sector 
            ORDER BY ((last_close - first_close) / first_close) ASC
        ) AS worst_rank
    FROM t
    JOIN companies c ON t.ticker = c.ticker
)

SELECT 
    b.sector,
    b.ticker AS best_stock,
    b.gain_pct AS best_gain,
    w.ticker AS worst_stock,
    w.gain_pct AS worst_gain
FROM r b
JOIN r w 
    ON b.sector = w.sector
WHERE b.best_rank = 1
  AND w.worst_rank = 1;

-- Query 6 — Sector Volatility Comparison

SELECT
c.sector,
ROUND(AVG(s.high - s.low),2) as avg_daily_range,
ROUND(STDDEV(s.close)) as price_stddev,
ROUND((AVG(s.high-s.low)/STDDEV(s.close))*100,2) as volatility_pct,
RANK() OVER (ORDER BY ROUND(STDDEV(s.close)) DESC) as volatility_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector

-- Query 7 — Number of Stocks per Sector with Positive Overall Return

WITH t as (SELECT 
s.ticker,
c.sector,
first_value(s.close) OVER (PARTITION BY s.ticker ORDER BY s.date) as first_close,
last_value(s.close) OVER (PARTITION BY s.ticker ORDER BY s.date
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_close
FROM stocks s
JOIN companies c ON s.ticker = c.ticker),            

r as(SELECT DISTINCT
sector,
ticker,
ROUND(((last_close-first_close)/first_close)*100,2) as overall_return
FROM t
WHERE ROUND(((last_close-first_close)/first_close)*100,2) > 0
ORDER BY sector)

SELECT DISTINCT
sector,
COUNT(*) OVER (PARTITION BY sector) as number_of_stocks
FROM r
ORDER BY number_of_stocks DESC

-- Query 8 — Sector Monthly Heatmap Data

SELECT 
    c.sector,
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    ROUND(AVG(s.close), 2) AS avg_monthly_close
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector, month
ORDER BY c.sector, month;

-- Query 9 — Sector Correlation: High Growth vs High Volume

SELECT 
    c.sector,
    ROUND(((AVG(last_close) - AVG(first_close)) / AVG(first_close)) * 100, 2) AS growth_pct,
    ROUND(AVG(s.volume), 0) AS avg_volume,
    CASE 
        WHEN ((AVG(last_close) - AVG(first_close)) / AVG(first_close)) * 100 > 50 
             AND AVG(s.volume) > 1000000 THEN 'High Growth + High Volume'
        WHEN ((AVG(last_close) - AVG(first_close)) / AVG(first_close)) * 100 > 50 
             THEN 'High Growth + Low Volume'
        WHEN AVG(s.volume) > 1000000 
             THEN 'Low Growth + High Volume'
        ELSE 'Low Growth + Low Volume'
    END AS sector_profile
FROM (
    SELECT 
        ticker,
        FIRST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date) AS first_close,
        LAST_VALUE(close)  OVER (
            PARTITION BY ticker ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_close
    FROM stocks
) t
JOIN stocks s ON t.ticker = s.ticker
JOIN companies c ON t.ticker = c.ticker
GROUP BY c.sector
ORDER BY growth_pct DESC;

-- Query 10 — Final Sector Scorecard (Summary Table)

SELECT 
    c.sector,
    COUNT(DISTINCT s.ticker) AS total_stocks,
    ROUND(AVG(s.close), 2) AS avg_price,
    ROUND(STDDEV(s.close), 2) AS volatility,
    ROUND(AVG(s.volume), 0) AS avg_volume,
    RANK() OVER (ORDER BY AVG(s.close) DESC) AS price_rank,
    RANK() OVER (ORDER BY STDDEV(s.close) DESC) AS risk_rank,
    RANK() OVER (ORDER BY AVG(s.volume) DESC) AS volume_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector
ORDER BY price_rank;