CREATE OR ALTER VIEW core.vw_rolling_volatility
AS
SELECT
    symbol,
    trade_date,
    log_return,
    STDEV(log_return) OVER (
        PARTITION BY symbol
        ORDER BY trade_date
        ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
    ) AS rolling_20d_volatility
FROM core.vw_log_returns;