-- Drop development database only
-- Terminates acitve connections before dropping the database

IF DB_ID('FinancialMetrics_dev') IS NOT NULL
BEGIN
    -- Force disconnect active sessions
    ALTER DATABASE FinancialMetrics_dev
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- DROP development database
    DROP DATABASE FinancialMetrics_dev;
END;