-- Module 5 — Volume Analysis

USE stock_analysis;
SELECT * FROM stocks;
SELECT * FROM companies;

-- Query 1 — Top 10 Most Traded Stocks (Avg Daily Volume)

SELECT 
s.ticker,
c.name,
c.sector,
ROUND(AVG(s.volume),2) as avg_daily_volume,
SUM(s.volume) as total_volume_traded
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY avg_daily_volume DESC
LIMIT 10;

-- Query 2 — Least Traded Stocks (Lowest Avg Volume)

SELECT 
s.ticker,
c.name,
c.sector,
ROUND(AVG(s.volume),2) as avg_volume_traded
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY avg_volume_traded ASC
LIMIT 10;

-- Query 3 — Monthly Volume Trend (Is Market Activity Growing?)

SELECT
DATE_FORMAT(date, '%Y-%m') AS month,
-- MONTH(date) as months,
SUM(volume) as volume_traded
FROM stocks
GROUP BY month
ORDER BY month;

-- Query 4 — Unusual Volume Days (2x Above Average)


WITH t as (SELECT
date,
volume,
AVG(volume) OVER () as avg_volume_traded
FROM stocks)

SELECT
date,
volume
FROM t
WHERE volume > (2 * avg_volume_traded)
ORDER BY volume DESC;

-- Query 5 — Volume vs Price Relationship

SELECT
s.ticker,
c.name,
s.date,
ROUND((s.close),2) as close_price,
s.volume,
CASE
	WHEN s.close > LAG(s.close) OVER (PARTITION BY s.ticker ORDER BY s.date) 
		AND s.volume > AVG(s.volume) OVER (PARTITION BY s.ticker)
		THEN 'HIGH VOLUME UP DAY'
	WHEN s.close > LAG(s.close) OVER (PARTITION BY s.ticker ORDER BY s.date)
		AND s.volume < AVG(s.volume) OVER (PARTITION BY s.ticker)
		THEN 'LOW VOLUME UP DAY'
	WHEN s.volume > AVG(s.volume) OVER (PARTITION BY s.ticker)
		THEN 'HIGH VOLUME DOWN DAY'
	ELSE 'LOW VOLUME DOWN DAY'
END AS volume_price_signal
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
WHERE s.ticker IN ('AAPL', 'MSFT', 'TSLA', 'AMZN', 'GOOGL')
ORDER BY s.ticker, s.date 
LIMIT 50;

-- Query 6 — Top Volume Day per Stock (All Time Peak)

WITH t as (SELECT 
s.ticker,
c.name,
c.sector,
s.volume,
RANK() OVER (PARTITION BY s.ticker ORDER BY s.volume DESC) as  ticker_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker)

SELECT
ticker,
name,
sector,
volume
FROM t
WHERE ticker_rank = 1
ORDER BY ticker;

-- Query 7 — Yearly Volume Trend per Stock

SELECT
ticker,
year(date) as year,
SUM(volume) as yearly_volume 
FROM stocks
GROUP BY ticker, year
ORDER BY ticker;

-- Query 8 — Sector Total Volume Ranking

SELECT 
c.sector,
SUM(s.volume) as sector_total_volume,
RANK() OVER (ORDER BY SUM(s.volume) DESC) as sector_rank
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY c.sector
ORDER BY sector_total_volume DESC;

-- Query 9 — High Volume + High Price Gain Days (Strong Bullish Signal)

WITH t as (SELECT
ticker,
date,
volume,
AVG(volume) OVER () as avg_volume,
close - LAG(close) OVER (PARTITION BY ticker ORDER BY date) as price_gain
FROM stocks),

x as (SELECT
ticker,
date,
volume,
avg_volume,
price_gain,
AVG(price_gain) OVER () as avg_price_gain
FROM t
WHERE price_gain IS NOT NULL)

SELECT
ticker,
date,
volume,
avg_volume,
price_gain,
avg_price_gain
FROM x
WHERE volume > (2 * avg_volume) AND price_gain > (2 * avg_price_gain);

-- Query 10 — Volume Percentile Ranking per Stock

SELECT
ticker,
date,
volume,
(PERCENT_RANK() OVER (PARTITION BY ticker ORDER BY volume)) as volume_percentile
FROM stocks
ORDER BY ticker, volume_percentile DESC;









