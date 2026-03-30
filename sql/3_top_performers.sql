USE stock_analysis;
SELECT * FROM stocks;
SELECT * FROM companies;

## TOP PERFORMER

-- Query 1 -> Overall Top 10 Stocks by Total Price Gain 

#stock, Total price gain (Top 10)

SELECT
ticker,
first_close,
last_close,
ROUND((last_close - first_close),2) as absolute_gain,
ROUND(((last_close - first_close)/first_close )*100,2) as pct_gain
FROM(
SELECT distinct
ticker,
FIRST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
LAST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date
							ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks) as t
-- GROUP BY ticker, first_close, last_close #n problems like this, GROUP BY is actually being used just to remove duplicates, not to aggregate data
ORDER BY pct_gain DESC
LIMIT 10;
#We can use DISTINCT function instead of GROUP BY function to remove the distinct function.

##More cleaner version

WITH price_data AS (
SELECT 
ticker,
FIRST_VALUE (close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
LAST_VALUE (close) OVER (PARTITION BY ticker ORDER BY date 
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks)

SELECT DISTINCT 
ticker,
first_close,
last_close,
ROUND((last_close-first_close),2) as absolute_gain,
ROUND(((last_close-first_close)/first_close)*100,2) as pct_gain
FROM price_data
ORDER BY pct_gain DESC
LIMIT 10;

-- Query 2 -> Bottom 10 Worst Performing Stocks

WITH price_data AS (
SELECT 
ticker,
FIRST_VALUE (close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
LAST_VALUE (close) OVER (PARTITION BY ticker ORDER BY date 
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks)

SELECT DISTINCT 
ticker,
first_close,
last_close,
ROUND((last_close-first_close),2) as absolute_gain,
ROUND(((last_close-first_close)/first_close)*100,2) as pct_gain
FROM price_data
ORDER BY pct_gain ASC
LIMIT 10;

-- Query 3 -> Top Performer per Sector

WITH t as (SELECT 
ticker,
FIRST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date) as first_close,
LAST_VALUE(close) OVER (PARTITION BY ticker ORDER BY date
						ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_close
FROM stocks),
ranked as (SELECT DISTINCT
c.sector,
t.ticker,
c.name,
ROUND(((last_close - first_close)/first_close)*100,2) as pct_gain,
RANK() OVER (PARTITION BY c.sector ORDER BY ROUND(((last_close - first_close)/first_close)*100,2) DESC) as rnk
FROM t
JOIN companies c ON t.ticker = c.ticker)

SELECT
	sector,
    ticker,
    name,
    pct_gain
FROM ranked
WHERE rnk = 1
ORDER BY pct_gain DESC;

-- Query 4 -> Top 10 Stocks by Highest Average Closing Price

##Stocks, Avg. closing price

SELECT
s.ticker,
c.name,
c.sector,
ROUND(avg(s.close),2) as avg_close_price
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY avg_close_price DESC
LIMIT 10; 

-- Query 5 -> Top 10 Stocks by Highest Single Day Closing Price

SELECT
s.ticker,
c.name,
c.sector,
ROUND(max(s.close),2) as max_close_price
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY s.ticker, c.name, c.sector
ORDER BY max_close_price DESC
LIMIT 10;

-- Query 6 -> Most Consistent Top Performers (Ranked in Top 50 Every Year)

WITH x as (SELECT 
ticker,
year(date) as year,
ROUND((Avg(close)),2) as avg_price_value,
RANK() OVER (PARTITION BY year(date) ORDER BY ROUND((Avg(close)),2) DESC) as rnk
FROM stocks
GROUP BY ticker, year(date))

SELECT 
ticker,
COUNT(*) as years_in_top50
From x
WHERE rnk <=50
GROUP BY ticker
HAVING years_in_top50 >=4
ORDER BY  years_in_top50 DESC, ticker ;

-- Query 7 -> Top 5 Stocks Each Year 

WITH x as (SELECT 
ticker,
year(date) as year,
ROUND((Avg(close)),2) as avg_price_value,
RANK() OVER (PARTITION BY year(date) ORDER BY ROUND((Avg(close)),2) DESC) as rnk
FROM stocks
GROUP BY ticker, year(date)
)

SELECT
ticker,
year
FROM x
WHERE rnk <= 5

-- Query 8 -> Sector Average Performance Ranking

WITH x as (SELECT DISTINCT
s.ticker,
c.sector,
ROUND(avg(s.close),2) as avg_close
FROM stocks s
JOIN companies c ON s.ticker = c.ticker
GROUP BY ticker)


SELECT
sector,
ROUND(avg(avg_close),2) as avg_sector_close
FROM x
GROUP BY sector
ORDER BY avg_sector_close DESC;

SELECT 
	c.sector,
    ROUND(avg(s.close),2) as avg_sector_close,
    ROUND(max(s.close),2) as max_price,
    ROUND(min(s.close),2) as min_price,
    RANK() OVER (ORDER BY ROUND(avg(s.close),2) DESC) as sector_rank
FROM companies c
JOIN stocks s ON c.ticker = s.ticker
GROUP BY sector;

## PARTITION BY is used when multiple ranking list is available.