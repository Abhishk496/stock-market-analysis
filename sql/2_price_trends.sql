USE stock_analysis;
SELECT * FROM stocks;


-- Query 1 -> Monthly Average Closing Price per Stock

SELECT ticker,
	date_format(date, '%Y-%m') AS month,
    ROUND(AVG(close),2) AS avg_close
FROM stocks
GROUP BY ticker, month
ORDER BY ticker, month;

-- Query 2 -> Yearly Average Price per Stock

SELECT ticker,
	year(date) AS year,
    round(avg(close), 2) AS avg_close,
    round(min(close), 2) AS min_close,
    round(max(close), 2) AS max_close
FROM stocks
GROUP BY ticker, year
ORDER BY ticker, year;

-- Query 3 -> Best Performing Year per Stock

SELECT 
    ticker,
    year,
    avg_close
FROM (
    SELECT 
        ticker,
        YEAR(date) AS year,
        ROUND(AVG(close), 2) AS avg_close,
        RANK() OVER (PARTITION BY ticker ORDER BY AVG(close) DESC) AS rnk
    FROM stocks
    GROUP BY ticker, year
) AS ranked
WHERE rnk = 1
ORDER BY avg_close DESC
LIMIT 20;

-- Query 4 -> Year over Year Price Growth %
        
SELECT
ticker,
year,
avg_close,
prev_close,
(((avg_close - prev_close) / prev_close)*100) AS yoy_growth_pct
FROM(
	SELECT 
    ticker,
    YEAR(date) AS year,
    ROUND(AVG(close), 2) AS avg_close,
    LAG(ROUND(AVG(close), 2)) OVER (PARTITION BY ticker ORDER BY YEAR(date)) AS prev_close
FROM stocks
GROUP BY ticker, year
) AS t
WHERE Prev_close is NOT NULL
ORDER BY yoy_growth_pct DESC
LIMIT 20;

-- Query 5 -> 30-Day Moving Average (Rolling Price Trend)

SELECT
ticker,
date,
close,
ROUND((Avg(close) OVER (
PARTITION BY ticker
ORDER BY date
ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)), 2) AS moving_avg_30d
FROM stocks
WHERE ticker IN ('NVDA', 'AMD', 'MU', 'ILMN','AAL')
ORDER BY ticker, date;

-- Query 6 -> Stocks That Consistently Grew (Price Higher Each Year)


SELECT ticker, COUNT(*) as Years_of_growth
FROM
(select 
	ticker,
    YEAR(date) as year,
    ROUND(AVG(close),2) as avg_close,
    LAG(ROUND(AVG(close),2)) OVER (PARTITION BY ticker ORDER BY YEAR(date)) as Prev_close
FROM stocks
GROUP BY ticker, year
) as YoY
WHERE avg_close > prev_close
GROUP BY ticker
HAVING Years_of_growth >= 3
ORDER BY Years_of_growth DESC; 
    
    
-- Query 7 -> Biggest Single Day Price Jump of every stock
  
SELECT ticker, date, price_jump_pct
FROM (
SELECT
		ticker,
        date,
        ((close-open)/open)*100 as price_jump_pct,
        RANK() OVER (PARTITION BY ticker ORDER BY ((close-open)/open)*100 DESC) as rnk
FROM stocks) as t
WHERE rnk = 1
ORDER BY price_jump_pct DESC;













