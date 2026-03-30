-- I have downloaded the CSV files from Kaggle (main stock data and related companies data)

-- 1. Create a Database in MySQL Workbench

CREATE DATABASE stock_analysis;
USE stock_analysis;

-- 2. Create the Table

CREATE TABLE stocks (
	id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    open DECIMAL (10,2),
    high DECIMAL (10,2),
    low DECIMAL (10,2),
    close DECIMAL(10,2),
    volume BIGINT,
    ticker VARCHAR(10));

-- 3.  I have imported the CSV data into MySQL Workbench.

-- 4. I have used some basic queries to check the import of the data.

SELECT COUNT(*) FROM stocks;
SELECT * FROM stocks LIMIT 10;
SELECT distinct ticker from stocks order by ticker;
SELECT COUNT(distinct ticker) from stocks;

-- 5. Then, I have done the data cleaning and checked the data range.

SELECT * FROM stocks
WHERE date is NULL
	or open is NULL
    or high is NULL
    or low is NULL
    or close is NULL
    or volume is NULL
    or ticker is NULL;

SELECT MIN(date), MAX(date) FROM stocks

-- 6. I have created the companies table in the same database and imported data from the CSV file and verified it.

CREATE TABLE companies (
	ticker VARCHAR(10) PRIMARY KEY,
    name VARCHAR (100),
    sector VARCHAR (100),
    industry VARCHAR (100)
);


SELECT COUNT(*) FROM companies; 
SELECT DISTINCT sector FROM companies;
