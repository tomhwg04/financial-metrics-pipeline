CREATE TABLE log.batch_run (
    batch_id bigint IDENTITY(1, 1),
    source varchar(40) NOT NULL,
    started_at datetime2 NOT NULL DEFAULT(SYSDATETIME()),
    finished_at datetime2 NULL,
    [status] varchar(10) NOT NULL,
    rows_inserted int NOT NULL DEFAULT(0),
    error_message nvarchar(4000) NULL,
    CONSTRAINT PK_batch_run PRIMARY KEY(batch_id),
    CONSTRAINT CK_batch_run_status CHECK(status in ('STARTED', 'SUCCESS', 'FAILED'))
)