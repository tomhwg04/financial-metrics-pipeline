SELECT TOP 10 *
FROM core.vw_rolling_volatility
WHERE rolling_20d_volatility IS NOT NULL
ORDER BY rolling_20d_volatility DESC;