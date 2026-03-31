IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE [name] = 'core_last_updated_at'
    AND object_id = OBJECT_ID('core.prices_daily')
)
BEGIN
    ALTER TABLE core.prices_daily
    ADD core_last_updated_at datetime2 NOT NULL DEFAULT(SYSDATETIME())
END;

-- Migration: Adds core_last_updated_at column to existing core.prices_daily tables if not already present
-- Used to track the last update timestamp for each row