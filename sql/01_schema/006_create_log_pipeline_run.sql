CREATE TABLE log.pipeline_run(
    run_id bigint IDENTITY(1, 1),
    [procedure_name] varchar(128) NOT NULL,
    started_at datetime2 NOT NULL DEFAULT(SYSDATETIME()),
    finished_at datetime2 NULL,
    [status] varchar(10) NOT NULL,
    symbol_filter varchar(20),
    trade_date_filter date,
    source_filter varchar(40),
    rows_in_staging_total int NOT NULL DEFAULT(0),
    rows_in_staging_scope int NOT NULL DEFAULT(0),
    best_rows_selected int NOT NULL DEFAULT(0),
    rows_inserted int NOT NULL DEFAULT(0),
    rows_updated int NOT NULL DEFAULT(0),
    error_message nvarchar(4000) NULL,
    CONSTRAINT PK_pipeline_run PRIMARY KEY(run_id),
    CONSTRAINT CK_pipeline_run_status CHECK(status IN ('STARTED', 'SUCCESS', 'FAILED'))
);