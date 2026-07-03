SELECT TOP 10 *
FROM core.vw_daily_returns
WHERE daily_return IS NOT NULL
ORDER BY daily_return DESC;