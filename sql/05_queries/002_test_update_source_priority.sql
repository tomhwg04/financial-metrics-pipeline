-- Safety check: ensure script runs only in dev database
IF DB_NAME() <> 'FinancialMetrics_dev'
BEGIN
    PRINT 'This script must be run in FinancialMetrics_dev database.'
    RETURN;
END

-- Test Case 1: Worse source should not overwrite better source

-- Reset test data
TRUNCATE TABLE core.prices_daily;
TRUNCATE TABLE stg.prices_daily;

-- Setup: Load YahooFinance data into core first.
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
    'ASML', 
    '2026-04-30', 
    1181.40, 
    1225.80, 
    1176.20, 
    1223.80, 
    1223.80, 
    2395478, 
    'YahooFinance'
);

EXEC core.upsert_prices_daily;

-- Action: Insert CSV data for the same symbol and trade_date.
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
    'ASML', 
    '2026-04-30', 
    1181.40, 
    1225.80, 
    1176.20, 
    1223.80, 
    1223.80, 
    2395478,   
    'CSV'
);

EXEC core.upsert_prices_daily;

-- Expected: Core should remain unchanged and keep YahooFinance as source.
SELECT symbol, trade_date, [close], volume, source, ingested_at, core_last_updated_at
FROM core.prices_daily;

-- Test Case 2: Better source should overwrite worse source

-- Reset test data
TRUNCATE TABLE core.prices_daily;
TRUNCATE TABLE stg.prices_daily;

-- Setup: Load CSV data into core first.
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
    'GS', 
    '2026-04-30', 
    770.20, 
    787.80, 
    770.20, 
    786.00, 
    786.00, 
    2795610, 
    'CSV'
);

EXEC core.upsert_prices_daily;

-- Action: Insert YahooFinance data for the same symbol and trade_date.
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
    'GS', 
    '2026-04-30', 
    770.20, 
    787.80, 
    770.20, 
    786.00, 
    786.00, 
    2795610,  
    'YahooFinance'
);

EXEC core.upsert_prices_daily;

-- Expected: Core should be updated and source should change to YahooFinance.
SELECT symbol, trade_date, [close], volume, source, ingested_at, core_last_updated_at
FROM core.prices_daily;