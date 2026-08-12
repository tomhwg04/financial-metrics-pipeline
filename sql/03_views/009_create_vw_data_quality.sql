CREATE OR ALTER VIEW core.vw_data_quality
AS
SELECT 
    p.symbol,
    p.trade_date,
    CASE
        WHEN p.[open] > 0
         AND p.high > 0
         AND p.low > 0
         AND p.[close] > 0 THEN 1
        ELSE 0
    END AS valid_price_values,
    CASE 
        WHEN p.volume >= 0 THEN 1
        ELSE 0
    END AS valid_volume,
    CASE
        WHEN p.low <= p.high THEN 1
        ELSE 0
    END AS valid_high_low,
    CASE
        WHEN (p.low <= p.[open] AND p.[open] <= p.high) THEN 1
        ELSE 0
    END AS valid_open_range,
    CASE
        WHEN (p.low <= p.[close] AND p.[close] <= p.high) THEN 1
        ELSE 0
    END AS valid_close_range,
    r.daily_return,
    CASE
        WHEN ABS(r.daily_return) > 0.3 THEN 1
        ELSE 0
    END AS large_daily_move_flag
FROM core.prices_daily p
LEFT JOIN core.vw_daily_returns r
    ON p.symbol = r.symbol
   AND p.trade_date = r.trade_date;