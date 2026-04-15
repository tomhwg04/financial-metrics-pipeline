-- Seed script for stg.prices_daily test scenarios
-- Purpose:
-- 1. Reset dev test data
-- 2. Insert controlled staging records
-- 3. Validate insert, update, source-priority and NULL-handling cases
--
-- Usage:
-- 1. Run this script
-- 2. Run sql/05_queries/001_load_core_prices_daily.sql
-- 3. Verify results in core.prices_daily

-- Safety check: ensure script runs only in dev database
IF DB_NAME() <> 'FinancialMetrics_dev'
BEGIN
    PRINT 'This script must be run in FinancialMetrics_dev database.'
    RETURN;
END

-- Reset test data
TRUNCATE TABLE core.prices_daily;
TRUNCATE TABLE stg.prices_daily;

-- Test case 1: Insert case
-- New business key should be inserted into core
INSERT INTO stg.prices_daily(
    batch_id, 
    symbol, 
    trade_date, 
    [open], 
    high, 
    low, 
    [close], 
    adj_close, 
    volume, 
    source
)
VALUES(
    1, 
    'AAPL', 
    '2026-04-15', 
    220.00, 
    220.00, 
    218.35, 
    219.10, 
    219.10, 
    2867493, 
    'YahooFinance'
);

-- Test case 2: Update case
-- Same symbol and trade_date, same source, newer version should win
INSERT INTO stg.prices_daily(
    batch_id, 
    symbol, 
    trade_date, 
    [open], 
    high, 
    low, 
    [close], 
    adj_close, 
    volume, 
    source
)
VALUES(
    2, 
    'AAPL', 
    '2026-04-15', 
    219.30, 
    224.85, 
    218.75, 
    224.90, 
    224.90, 
    3576445, 
    'YahooFinance'
);

-- Test case 3: Source priority case
-- YahooFinance should win over CSV for the same business key
INSERT INTO stg.prices_daily(
    batch_id, 
    symbol, 
    trade_date, 
    [open], 
    high, 
    low, 
    [close], 
    adj_close, 
    volume, 
    source
)
VALUES(
    3,
    'MSFT',
    '2026-04-15',
    334.50,
    350.55,
    334.15,
    350.30,
    350.30,
    2579487,
    'YahooFinance'
);

INSERT INTO stg.prices_daily(
    batch_id, 
    symbol, 
    trade_date, 
    [open], 
    high, 
    low, 
    [close], 
    adj_close, 
    volume, 
    source
)
VALUES(
    4,
    'MSFT',
    '2026-04-15',
    327.60,
    334.30,
    327.60,
    333.20,
    333.20,
    1049285,
    'CSV'
);

-- Test case 4: NULL handling case
-- Row with NULL adj_close should be loaded successfully into core
INSERT INTO stg.prices_daily(
    batch_id, 
    symbol, 
    trade_date, 
    [open], 
    high, 
    low, 
    [close], 
    adj_close, 
    volume, 
    source
)
VALUES(
    5,
    'NVDA',
    '2026-04-15',
    165.70,
    169.34,
    165.30,
    167.50,
    NULL,
    3059860,
    'YahooFinance'
)