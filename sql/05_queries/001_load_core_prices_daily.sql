IF OBJECT_ID('tempdb..#best_rows') IS NOT NULL
    DROP TABLE #best_rows;

WITH base_data AS (
    SELECT symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at, CASE WHEN source = 'YahooFinance' THEN 1 ELSE 2 END AS source_priority
    FROM stg.prices_daily
), 
    ranked_data AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY symbol, trade_date
        ORDER BY source_priority ASC, ingested_at DESC
    ) AS rn
    FROM base_data
)
SELECT symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at, source_priority
INTO #best_rows
FROM ranked_data
WHERE rn = 1;

UPDATE c
SET 
    c.[open] = b.[open],
    c.high = b.high,
    c.low = b.low,
    c.[close] = b.[close],
    c.adj_close = b.adj_close,
    c.volume = b.volume,
    c.source = b.source,
    c.ingested_at = b.ingested_at,
    c.core_last_updated_at = SYSDATETIME()
FROM core.prices_daily c
JOIN #best_rows b
ON c.symbol = b.symbol AND c.trade_date = b.trade_date
WHERE
    b.source_priority < CASE WHEN c.source = 'YahooFinance' THEN 1 ELSE 2 END 
    OR (
        b.source_priority = CASE WHEN c.source = 'YahooFinance' THEN 1 ELSE 2 END 
        AND b.ingested_at > c.ingested_at
    );

INSERT INTO core.prices_daily(symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at)
SELECT symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at
FROM #best_rows b
WHERE NOT EXISTS (
    SELECT 1
    FROM core.prices_daily c
    WHERE c.symbol = b.symbol
    AND c.trade_date = b.trade_date
)