CREATE VIEW log.vw_batch_run_summary
AS 
SELECT
    batch_id,
    source,
    [status],
    started_at,
    finished_at,
    DATEDIFF(MILLISECOND, started_at, finished_at) AS duration_ms,
    rows_inserted,
    error_message
FROM log.batch_run;