# Financial Metrics Pipeline

An end-to-end financial data engineering and quantitative analysis project built with **Microsoft SQL Server and Python**.

The pipeline ingests daily market data from Yahoo Finance, transforms and loads it into a staging layer, resolves duplicates through configurable source prioritization, and maintains a clean core dataset using transactional logic.

On top of the data pipeline, reusable SQL views and a Jupyter-based analysis layer provide financial metrics such as daily returns, rolling volatility, moving averages, momentum signals and data quality checks.

## Architecture

The project follows a layered architecture that separates data ingestion, transformation, configuration, monitoring and analysis.

```text
Yahoo Finance
      ↓
Python ingestion
      ↓
stg.prices_daily
      ↓
Source prioritization + deduplication
      ↓
core.upsert_prices_daily
      ↓
core.prices_daily
      ↓
SQL analytical views
      ↓
Jupyter market analysis
```

The SQL Server implementation is organized into four schemas:  

- **`stg`** — staging area for newly ingested market data
- **`core`** — cleaned, deduplicated and analysis-ready market data
- **`config`** — pipeline configuration such as source prioritization
- **`log`** — batch- and pipeline-level execution monitoring

For each `(symbol, trade_date)` combination, staging records are ranked by source priority, ingestion timestamp, batch ID and row ID. Only the highest-ranked record is considered for loading into the core layer.

Existing core records are updated only when the incoming record originates from a higher-priority source or from a source with the same priority and a newer ingestion timestamp.

This design allows multiple market data sources to coexist in staging while maintaining a single preferred record per symbol and trading day in the core layer.

## Key Features

- End-to-end market data pipeline using Python and Microsoft SQL Server
- Configurable multi-source prioritization and deduplication
- Transactional staging-to-core upsert logic with rollback handling
- Batch- and pipeline-level execution logging
- Reusable SQL views for quantitative metrics and monitoring
- Financial metrics including returns, volatility, moving averages and momentum
- Data quality validation
- Jupyter-based market analysis and visualization

## Project Structure

```text
financial-metrics-pipeline/
│
├── python/
│   ├── analysis/
│   │   └── market_analysis.ipynb
│   ├── ingestion/
│   │   └── load_yahoo_prices.py
│   ├── utils/
│   │   └── db.py
│   └── __init__.py
│
├── sql/
│   ├── 00_admin/
│   ├── 01_schema/
│   ├── 02_seed/
│   ├── 03_views/
│   ├── 04_procedures/
│   └── 05_queries/
│
├── .env.example
├── .gitattributes
├── .gitignore
├── requirements.txt
└── README.md
```

### Directory Overview

- **`python/analysis`** ─ Jupyter-based quantitative market analysis
- **`python/ingestion`** ─ market data ingestion and pipeline execution
- **`python/utils`** ─ shared utilities such as SQL Server connectivity
- **`sql/00_admin`** ─ database creation and development utility scripts
- **`sql/01_schema`** ─ schemas, tables, logging objects and indexes
- **`sql/02_seed`** ─ source configuration and development test data
- **`sql/03_views`** ─ operational and quantitative analytical views
- **`sql/04_procedures`** ─ reusable stored procedures for pipeline logic
- **`sql/05_queries`** ─ validation, monitoring, testing and example analytical queries

## Setup

### Database

1. Run `sql/00_admin/000_create_databases.sql`
2. Execute all scripts in `sql/01_schema/` in numerical order
3. Run `sql/02_seed/002_seed_config_source_priority.sql`
4. Execute all scripts in `sql/03_views/`
5. Execute `sql/04_procedures/001_create_upsert_prices_daily.sql`

> **Note:** Scripts in `sql/02_seed/` that contain development test data should be executed against `FinancialMetrics_dev`, as they may reset or truncate existing staging and core data.

### Python

Create and activate a virtual environment:  

```bash
python -m venv .venv
source .venv/Scripts/activate
pip install -r requirements.txt
``` 

### Environment

Copy `.env.example` to `.env` and adjust the values for your local environment:  

```env
SQL_SERVER=localhost\SQLEXPRESS
SQL_DATABASE=FinancialMetrics_dev
SQL_DRIVER=ODBC Driver 17 for SQL Server

TICKERS=AAPL, MSFT, NVDA, GOOG, AMZN, META, TSLA
START_DATE=2026-01-01
END_DATE=2026-07-01
SOURCE=YahooFinance
```

The local `.env` file is excluded from version control.

## Running the Pipeline

Run the ingestion module from the repository root:  

```bash
python -m python.ingestion.load_yahoo_prices
```

The pipeline downloads and transforms Yahoo Finance data, loads it into staging, executes the staging-to-core upsert process and records batch and pipeline execution logs.

The current Python ingestion implementation uses Yahoo Finance, while the SQL architecture supports additional sources through `config.source_priority`.

## Analysis & Notebook

The project includes a Jupyter notebook that uses the SQL analytical views for quantitative market analysis.

The notebook is located at:  

`python/analysis/market_analysis.ipynb`

It analyzes the Magnificent 7 using daily market data for the first two quarters of 2026 and covers:  

- daily return analysis
- return distribution comparison
- rolling volatility
- moving average signals
- 20-day momentum
- data quality validation

The notebook combines SQL-based metric calculation with Python-based analysis and visualization, keeping the financial logic reusable at the database level while using Python for exploration and presentation.

The notebook assumes that the pipeline has already populated the database and that all required analytical views have been created before execution.

## Testing, Logging & Data Quality

The project includes several mechanisms to validate pipeline behaviour and monitor data quality.

### Testing

Development seed and query scripts validate insert, update, source-priority, `NULL` handling and error scenarios.

Additional validation queries are available in `sql/05_queries/`.

### Logging

Pipeline execution is tracked at two levels:  

- **`log.batch_run`** ─ monitors Python ingestion batches
- **`log.pipeline_run`** ─ monitors staging-to-core processing

Logged information includes execution status, timestamps, row counts, inserted and updated records, applied filters and error messages.

### Data Quality

The analytical layer includes dedicated checks for:  

- invalid price values
- invalid volume
- inconsistent high/low relationships
- open or close prices outside the daily trading range
- unusually large daily price movements

These checks help verify that the dataset is internally consistent before it is used for quantitative analysis.

## Future Work

Potential extensions of the project include:  

- integrating additional market data providers to further demonstrate the existing multi-source architecture
- expanding the analysis to additional assets and longer time horizons
- adding further technical indicators such as RSI, MACD and Bollinger Bands
- extending the analytical layer with risk metrics such as cumulative returns, Sharpe ratio and maximum drawdown
- automating recurring ingestion runs for continuous data updates

## Disclaimer

This project was created for educational and portfolio purposes.

It is not intended to provide investment advice, trading recommendations or production-grade financial market infrastructure.