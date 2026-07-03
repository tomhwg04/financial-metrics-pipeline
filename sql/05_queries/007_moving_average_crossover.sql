SELECT 
    ma.symbol,
    ma.trade_date,
    ma.adj_close,
    ma.moving_20d_average,
    ma.moving_50d_average
FROM core.vw_moving_averages ma
JOIN core.vw_latest_prices lp
    ON ma.symbol = lp.symbol
   AND ma.trade_date = lp.trade_date
WHERE ma.moving_20d_average > ma.moving_50d_average
    AND ma.moving_20d_average IS NOT NULL
    AND ma.moving_50d_average IS NOT NULL
ORDER BY 
    (moving_20d_average - moving_50d_average) DESC;