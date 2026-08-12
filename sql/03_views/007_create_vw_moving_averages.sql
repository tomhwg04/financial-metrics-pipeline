CREATE OR ALTER VIEW core.vw_moving_averages
AS 
WITH moving_average_base AS (
    SELECT
        symbol,
        trade_date,
        adj_close,
        COUNT(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS observations_20d,
        COUNT(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS observations_50d,
        AVG(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS raw_moving_20d_average,
        AVG(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY trade_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS raw_moving_50d_average
    FROM core.prices_daily
)
SELECT 
    symbol,
    trade_date,
    adj_close,
    CASE
        WHEN observations_20d >= 20 THEN raw_moving_20d_average
        ELSE NULL
    END AS moving_20d_average,
    CASE
        WHEN observations_50d >= 50 THEN raw_moving_50d_average
        ELSE NULL
    END AS moving_50d_average
FROM moving_average_base;