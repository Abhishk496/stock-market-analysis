## Volatility Analysis

USE stock_analysis;
SELECT * FROM stocks;
SELECT * FROM companies;

# Query1 - Avg. Daily Price Range

SELECT 
s.ticker,
c.name,
ROUND(avg(s.high-s.low),2) as avg_daily_price_range,
ROUND(max(s.high-s.low),2) as max_daily_price_range,
ROUND(min(s.high-s.low),2) as min_daily_price_range
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY ticker
ORDER BY avg_daily_price_range DESC;

# Query2 - Standard Deviation of Closing Price (Statistical Volatility)

SELECT
s.ticker,
c.name,
ROUND(STDDEV(s.close),2) as price_stddev,
ROUND(AVG(s.close),2) as price_avg,
ROUND((STDDEV(s.close)/AVG(s.close))*100,2) as price_coefficient_of_variation
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY ticker
ORDER BY price_coefficient_of_variation;

# Query 3 — Most Volatile Stocks by Sector

WITH volatility_data as (SELECT
c.sector,
s.ticker,
c.name,
ROUND(STDDEV(s.close),2) as price_stddev,
ROUND(AVG(s.close),2) as price_avg,
ROUND((STDDEV(s.close)/AVG(s.close))*100,2) as price_coefficient_of_variation,
RANK() OVER (PARTITION BY sector ORDER BY ROUND((STDDEV(s.close)/AVG(s.close))*100,2) DESC) as stocks_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY ticker
ORDER BY sector, price_coefficient_of_variation DESC)

SELECT
sector,
ticker,
name
FROM volatility_data
WHERE stocks_rank = 1
ORDER BY price_coefficient_of_variation DESC;

-- Query 4 -> Daily Return % (Day over Day Change)

WITH price_data as (SELECT
ticker,
date,
close,
LAG(close) OVER (PARTITION BY ticker ORDER BY date) as prev_close
FROM stocks)

SELECT
ticker,
date,
close,
prev_close,
ROUND(((close-prev_close)/prev_close)*100,2) as daily_pct_change
FROM price_data
WHERE prev_close is NOT NULL
ORDER BY ABS(daily_pct_change) DESC
LIMIT 10;

-- Query5 -> Average Daily Return Volatility per Stock

WITH t as (
SELECT
ticker,
date,
ROUND(((close - LAG(close) OVER (PARTITION BY ticker ORDER BY date))/ LAG(close) OVER (PARTITION BY ticker ORDER BY date))*100,2) as daily_return_pct
FROM stocks)

SELECT 
ticker,
ROUND(AVG(ABS(daily_return_pct)),2) as avg_abs_daily_return_pct,
ROUND(STDDEV(daily_return_pct),2) as return_volatility,
ROUND(MAX(daily_return_pct),2) as max_return,
ROUND(MIN(daily_return_pct),2) as min_return
FROM t
WHERE daily_return_pct IS NOT NULL
GROUP BY ticker
ORDER BY return_volatility DESC
LIMIT 10;

-- Query 6 —> Least Volatile (Most Stable) Stocks

WITH t as (SELECT 
ticker,
date,
ROUND(((close - LAG(close) OVER (PARTITION BY ticker ORDER BY date))/ LAG(close) OVER (PARTITION BY ticker ORDER BY date))*100,2) as daily_return_pct
FROM stocks)

SELECT 
ticker,
ROUND(stddev(daily_return_pct),2) as return_volatility
FROM t
WHERE daily_return_pct IS NOT NULL
GROUP BY ticker
ORDER BY return_volatility ASC
LIMIT 10;

-- OR (both have different logic)

SELECT
s.ticker,
c.name,
c.sector,
ROUND(STDDEV(s.close),2) as price_volatility,
ROUND(AVG(s.close),2) as avg_price,
ROUND(STDDEV(s.close)/AVG(s.close),2) as price_variation
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY price_variation ASC
LIMIT 10;

-- Query 7 —> Yearly Volatility Trend per Stock

SELECT
s.ticker,
YEAR(s.date) as year,
ROUND(STDDEV(s.close),2) as price_volatility,
ROUND(AVG(s.close),2) as avg_price,
ROUND(STDDEV(s.close)/AVG(s.close),2) as price_variation
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, YEAR(s.date)
ORDER BY s.ticker

-- Query 8 —> High Volatility Days (Price Moved More Than 5%)

WITH t as (
SELECT 
ticker,
date,
ABS(ROUND(((close - LAG(close) OVER (PARTITION BY ticker ORDER BY date))/LAG(close) OVER (PARTITION BY ticker ORDER BY date))*100,2)) as abs_percent_change
FROM stocks)

SELECT
date,
abs_percent_change
FROM t
WHERE abs_percent_change is NOT NULL and abs_percent_change > 5
ORDER BY abs_percent_change DESC
LIMIT 15;

-- OR (Both have different logic)

SELECT 
    s.ticker,
    c.name,
    s.date,
    ROUND(s.close, 2) AS close_price,
    ROUND(daily_return_pct, 2) AS daily_return_pct
FROM (
    SELECT 
        ticker,
        date,
        close,
        ROUND(((close - LAG(close) OVER (PARTITION BY ticker ORDER BY date)) /
               LAG(close) OVER (PARTITION BY ticker ORDER BY date)) * 100, 2) AS daily_return_pct
    FROM stocks
) s
JOIN companies c ON s.ticker = c.ticker
WHERE ABS(daily_return_pct) > 5
ORDER BY ABS(daily_return_pct) DESC
LIMIT 15;

-- Query 9 — Volatility Rank per Sector (Sector Risk Table)

WITH t as (SELECT 
s.ticker,
c.name,
c.sector,
ROUND(STDDEV(s.close),2) as price_volatility
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY price_volatility DESC)

SELECT
sector,
ROUND(AVG(price_volatility),2) as avg_price_volatility,
RANK() OVER (ORDER BY ROUND(AVG(price_volatility),2) DESC) as sector_rank
FROM t
GROUP BY sector;

-- OR (Both have different logic)

SELECT 
c.sector,
ROUND(STDDEV(s.close),2) as price_volatility,
RANK() OVER (ORDER BY ROUND(STDDEV(s.close),2) DESC) as sector_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY sector
LIMIT 10;


