IF NOT EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'FinancialMetrics_dev'
)
BEGIN
CREATE DATABASE FinancialMetrics_dev
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'FinancialMetrics_prod'
)
BEGIN
CREATE DATABASE FinancialMetrics_prod
END;