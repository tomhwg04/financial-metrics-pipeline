IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
EXEC('CREATE SCHEMA stg;')
END;

IF NOT EXISTS (
    SELECT 1 
    FROM sys.schemas
    WHERE name = 'core'
)
BEGIN
EXEC('CREATE SCHEMA core;')
END;