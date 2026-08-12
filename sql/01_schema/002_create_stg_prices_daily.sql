CREATE TABLE stg.prices_daily(
    row_id bigint IDENTITY(1, 1),
    batch_id bigint NOT NULL,
    symbol varchar(20) NOT NULL,
    trade_date date NOT NULL,
    [open] decimal(18, 6) NOT NULL,
    high decimal(18, 6) NOT NULL,
    low decimal(18, 6) NOT NULL,
    [close] decimal(18, 6) NOT NULL,
    adj_close decimal(18, 6),
    volume bigint NOT NULL,
    source varchar(40) NOT NULL,
    ingested_at datetime2 NOT NULL DEFAULT(SYSDATETIME()),
    CONSTRAINT PK_stg_prices_daily PRIMARY KEY(row_id)
);