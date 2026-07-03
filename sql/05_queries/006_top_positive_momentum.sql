SELECT *
FROM core.vw_momentum_signals
WHERE momentum_20d > 0
ORDER BY momentum_20d DESC;