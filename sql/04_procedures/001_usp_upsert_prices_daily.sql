CREATE OR ALTER PROCEDURE core.upsert_prices_daily 
    @symbol varchar(20) = NULL,
    @trade_date DATE = NULL,
    @source varchar(40) = NULL
AS
BEGIN
    DECLARE @run_id bigint = NULL
    DECLARE @rows_in_staging_total int = 0
    DECLARE @rows_in_staging_scope int = 0
    DECLARE @best_rows_selected int = 0
    DECLARE @rows_updated int = 0
    DECLARE @rows_inserted int = 0
    SET NOCOUNT ON;
    INSERT INTO log.pipeline_run([procedure_name], [status], symbol_filter, trade_date_filter, source_filter)
    VALUES('core.upsert_prices_daily', 'STARTED', @symbol, @trade_date, @source)
    SET @run_id = SCOPE_IDENTITY();

    BEGIN TRY
        SELECT @rows_in_staging_total = COUNT(*) 
        FROM stg.prices_daily;

        SELECT @rows_in_staging_scope = COUNT(*)
        FROM stg.prices_daily p
        JOIN config.source_priority sp
                ON p.source = sp.source
                AND sp.is_active = 1
                WHERE (@symbol IS NULL
                OR p.symbol = @symbol)
                AND (@trade_date IS NULL
                OR p.trade_date = @trade_date)
                AND (@source IS NULL
                OR p.source = @source);

        WITH base_data AS (
            SELECT row_id, batch_id, symbol, trade_date, [open], high, low, [close], adj_close, volume, p.source, ingested_at, sp.priority AS source_priority
            FROM stg.prices_daily p
            JOIN config.source_priority sp
            ON p.source = sp.source
            AND sp.is_active = 1
            WHERE (@symbol IS NULL
            OR p.symbol = @symbol)
            AND (@trade_date IS NULL
            OR p.trade_date = @trade_date)
            AND (@source IS NULL
            OR p.source = @source)
        ), 
            ranked_data AS (
            SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY symbol, trade_date
                ORDER BY source_priority ASC, 
                ingested_at DESC,
                batch_id DESC,
                row_id DESC
            ) AS rn
            FROM base_data
        )
            SELECT symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at, source_priority
            INTO #best_rows
            FROM ranked_data
            WHERE rn = 1;

            SELECT @best_rows_selected = COUNT(*)
            FROM #best_rows;

            BEGIN TRANSACTION;
                UPDATE c
                SET 
                    c.[open] = b.[open],
                    c.high = b.high,
                    c.low = b.low,
                    c.[close] = b.[close],
                    c.adj_close = b.adj_close,
                    c.volume = b.volume,
                    c.source = b.source,
                    c.ingested_at = b.ingested_at,
                    c.core_last_updated_at = SYSDATETIME()
                FROM core.prices_daily c
                JOIN #best_rows b
                ON c.symbol = b.symbol AND c.trade_date = b.trade_date
                JOIN config.source_priority current_sp
                ON c.source = current_sp.source
                WHERE
                    b.source_priority < current_sp.priority 
                    OR (
                        b.source_priority = current_sp.priority 
                        AND b.ingested_at > c.ingested_at
                    );

                SELECT @rows_updated = @@ROWCOUNT;

                INSERT INTO core.prices_daily(symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at)
                SELECT symbol, trade_date, [open], high, low, [close], adj_close, volume, source, ingested_at
                FROM #best_rows b
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM core.prices_daily c
                    WHERE c.symbol = b.symbol
                    AND c.trade_date = b.trade_date
                );

                SELECT @rows_inserted = @@ROWCOUNT;

                COMMIT;

                UPDATE l
                SET [status] = 'SUCCESS',
                    finished_at = SYSDATETIME(),
                    rows_in_staging_total = @rows_in_staging_total,
                    rows_in_staging_scope = @rows_in_staging_scope,
                    best_rows_selected = @best_rows_selected,
                    rows_updated = @rows_updated,
                    rows_inserted = @rows_inserted
                FROM log.pipeline_run l
                WHERE l.run_id = @run_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN 
            ROLLBACK;
        END

        UPDATE l
            SET [status] = 'FAILED',
                finished_at = SYSDATETIME(),
                error_message = ERROR_MESSAGE()
            FROM log.pipeline_run l
            WHERE l.run_id = @run_id;

        ;THROW;
    END CATCH
END