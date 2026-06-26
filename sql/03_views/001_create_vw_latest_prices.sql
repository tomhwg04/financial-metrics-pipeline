CREATE VIEW core.vw_latest_prices
AS
WITH ranked_prices AS (
    SELECT
        symbol,
        trade_date,
        [open],
        high,
        low,
        [close],
        adj_close,
        volume,
        source,
        ingested_at,
        core_created_at,
        core_last_updated_at,
        ROW_NUMBER() OVER (
            PARTITION BY symbol
            ORDER BY trade_date DESC
        ) AS rn
    FROM core.prices_daily
)
SELECT
    symbol,
    trade_date,
    [open],
    high,
    low,
    [close],
    adj_close,
    volume,
    source,
    ingested_at,
    core_created_at,
    core_last_updated_at
FROM ranked_prices
WHERE rn = 1;