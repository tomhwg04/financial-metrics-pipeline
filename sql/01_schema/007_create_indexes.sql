CREATE INDEX IX_stg_prices_daily_full_load_deduplication
ON stg.prices_daily(
    symbol,
    trade_date,
    ingested_at DESC,
    batch_id DESC,
    row_id DESC
);