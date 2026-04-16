# Financial Metrics SQL Project

This project implements a simple data pipeline for financial market data using the Microsoft SQL Server.

Data is loaded into a staging layer (stg) and transformed into a core layer (core) with deduplication, source prioritization and upsert logic.

## Current Scope

- dev and prod databases
- staging and core schemas
- daily prices staging and core tables
- load logic from `stg.prices_daily` to `core.prices_daily`

## Project Structure

```text
sql/
    00_admin    -- setup / utility scripts
    01_schema   -- create and alter table scripts
    02_seed     -- test data for stg
    05_queries  -- load logic (stg → core)
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

## Development Workflow

1. Run seed script:  
  `sql/02_seed/001_seed_stg_prices_daily_test_cases.sql`

2. Run load script:  
   `sql/05_queries/001_load_core_prices_daily.sql`

3. Verify results in:  
  `core.prices_daily`

## Seed Test Cases

The seed script covers the following scenarios:

- Insert: new business key is inserted into core
- Update: newer version overwrites previous data
- Source priority: a preferred source is selected over lower-priority sources
- NULL handling: `adj_close` can be `NULL`

## Notes

- Seed scripts should only be executed in the dev database.
- They will truncate staging and core tables.