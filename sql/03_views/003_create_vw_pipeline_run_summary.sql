CREATE VIEW log.vw_pipeline_run_summary
AS 
SELECT
    run_id,
    [procedure_name],
    [status],
    started_at,
    finished_at,
    DATEDIFF(MILLISECOND, started_at, finished_at) as duration_ms,
    symbol_filter,
    trade_date_filter,
    source_filter,
    rows_in_staging_total,
    rows_in_staging_scope,
    best_rows_selected,
    rows_inserted,
    rows_updated,
    error_message
FROM log.pipeline_run;