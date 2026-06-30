CREATE VIEW core.vw_daily_returns 
AS
WITH price_history AS (
    SELECT 
        symbol,
        trade_date,
        adj_close,
        LAG(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
        ) AS previous_adj_close
     FROM core.prices_daily
)
SELECT
    symbol,
    trade_date,
    adj_close,
    previous_adj_close,
    CASE
        WHEN previous_adj_close IS NULL THEN NULL
        WHEN previous_adj_close = 0 THEN NULL
        ELSE adj_close / previous_adj_close - 1
        END as daily_return
FROM price_history;