CREATE VIEW core.vw_momentum_signals
AS 
WITH momentum_base AS (
    SELECT
        symbol,
        trade_date,
        adj_close,
        LAG(adj_close, 20) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
        ) AS adj_close_20d_ago
    FROM core.prices_daily
)
SELECT 
    symbol,
    trade_date,
    adj_close,
    CASE
        WHEN adj_close_20d_ago IS NULL THEN NULL
        WHEN adj_close_20d_ago <= 0 THEN NULL
        ELSE adj_close / adj_close_20d_ago - 1
        END AS momentum_20d
FROM momentum_base;