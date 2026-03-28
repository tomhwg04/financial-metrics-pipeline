CREATE TABLE core.prices_daily(
    symbol varchar(20) NOT NULL,
    trade_date date NOT NULL,
    [open] decimal(18, 6) NOT NULL,
    high decimal(18, 6) NOT NULL,
    low decimal(18, 6) NOT NULL,
    [close] decimal(18, 6) NOT NULL,
    adj_close decimal(18, 6),
    volume bigint NOT NULL,
    source varchar(40) NOT NULL,
    ingested_at datetime2 NOT NULL,
    core_created_at datetime2 NOT NULL DEFAULT(SYSDATETIME()),
    PRIMARY KEY(symbol, trade_date)
);