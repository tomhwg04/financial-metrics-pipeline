# Financial Metrics SQL Project

This project implements a simple data pipeline for financial market data using Microsoft SQL Server.

Data is loaded into a staging layer (`stg`) and transformed into a core layer (`core`) with deduplication, source prioritization and upsert logic.

## Architecture

The pipeline is structured into three logical layers:  

- `stg` (staging): raw input data
- `core`: cleaned, deduplicated and business-ready data
- `config`: configuration tables controlling pipeline behaviour (e.g. source prioritization)

## Current Scope

- dev and prod databases
- staging and core schemas
- daily prices staging and core tables
- upsert procedure from `stg.prices_daily` to `core.prices_daily` with optional filtering by `symbol`, `trade_date` and `source`

## Project Structure

```text
sql/
    00_admin      -- setup / utility scripts
    01_schema     -- create and alter table scripts
    02_seed       -- test data for stg
    04_procedures -- stored procedures for reusable data pipeline logic (e.g. upserts)
    05_queries    -- legacy and ad-hoc queries (initial load logic, testing)
```

## Initial Setup

1. Create dev and prod databases:  
  `sql/00_admin/000_create_databases.sql`

2. Create schemas:  
  `sql/01_schema/001_initial_schema.sql`

3. Create staging table:  
  `sql/01_schema/002_create_stg_prices_daily.sql`

4. Create core table:  
  `sql/01_schema/003_create_core_prices_daily.sql`

5. Apply schema migration for existing core tables:  
  `sql/01_schema/004_alter_core_prices_daily_add_last_updated.sql`

6. Create source priority table:  
  `sql/01_schema/005_create_config_source_priority.sql`

7. Seed source priority configuration:  
  `sql/02_seed/002_seed_config_source_priority.sql`

8. Create upsert procedure:  
  `sql/04_procedures/001_usp_upsert_prices_daily.sql`

## Development Workflow

1. Run config seed script:  
  `sql/02_seed/002_seed_config_source_priority.sql`

2. Run staging seed script:  
  `sql/02_seed/001_seed_stg_prices_daily_test_cases.sql`

3. Execute upsert procedure:  
   `EXEC core.upsert_prices_daily;`

4. Verify results in:  
  `core.prices_daily`

## Procedure Parameters

The upsert procedure supports optional filtering parameters.
If a parameter is provided, only the matching subset of staging data is processed.
If no parameters are provided, all available staging data is processed.

Examples:  

Load all data:  
`EXEC core.upsert_prices_daily;`

Filter by symbol:  
`EXEC core.upsert_prices_daily @symbol = 'AAPL';`

Filter by trade date:  
`EXEC core.upsert_prices_daily @trade_date = '2026-04-15';`

Filter by source:  
`EXEC core.upsert_prices_daily @source = 'CSV';`

Combine filters:  
`EXEC core.upsert_prices_daily @symbol = 'AAPL', @trade_date = '2026-04-15';`

## Upsert Logic

Data is loaded from `stg.prices_daily` into `core.prices_daily` using the following rules:

### Deduplication

For each `(symbol, trade_date)`:  

- rows are ranked using:
  - source priority (ascending)
  - ingested_at (descending)
  - batch_id (descending)
  - row_id (descending)

- only the best-ranked row is considered

### Insert

- new `(symbol, trade_date)` combinations are inserted

### Update

Existing rows are updated only if:  

- the new row has a higher-priority source, or
- the new row has the same source priority but a newer `ingested_at`

### Source Filtering

- only active and configured sources are considered during processing

## Source Priority Configuration

Source prioritization is not hardcoded but managed via the table:

`config.source_priority`

This table defines:  

- which sources are allowed in the pipeline
- their priority (lower value = higher priority)
- whether a source is active

Only sources that are:  

- present in `config.source_priority`
- and marked as `is_active = 1`

are considered during the load from staging to core.

### Behaviour

- Unknown sources are ignored
- Inactive sources are ignored
- Existing data in `core` is still compared using the priority of its original source, even if the source is later deactivated

## Seed Test Cases

The seed script covers the following scenarios:

- Insert: new business key is inserted into core
- Update: newer version overwrites previous data
- Source priority: a preferred source is selected over lower-priority sources
- NULL handling: `adj_close` can be `NULL`

## Test Scenarios

Additional test scripts validate update behaviour of the upsert logic:  

- Worse source does not overwrite better source
- Better source overwrites worse source

See:  
`sql/05_queries/002_test_update_source_priority.sql`

## Notes

- Seed scripts should only be executed in the dev database.
- They will truncate staging and core tables.
- A legacy query-based version of the upsert logic still exists in sql/05_queries/...