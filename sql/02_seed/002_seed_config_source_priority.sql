IF DB_NAME() <> 'FinancialMetrics_dev'
BEGIN
    PRINT 'This script must be run in FinancialMetrics_dev database.'
    RETURN;
END

-- Reset test data
TRUNCATE TABLE config.source_priority;

INSERT INTO config.source_priority(
    source,
    [priority],
    is_active,
    [description]
)
VALUES(
     'YahooFinance',
    1,
    1,
    'YahooFinance API'
);

INSERT INTO config.source_priority(
    source,
    [priority],
    is_active,
    [description]
)
VALUES(
     'AlphaVantage',
    5,
    1,
    'AlphaVantage API'
);

INSERT INTO config.source_priority(
    source,
    [priority],
    is_active,
    [description]
)
VALUES(
     'CSV',
    10,
    1,
    'Manual import'
);

INSERT INTO config.source_priority(
    source,
    [priority],
    is_active,
    [description]
)
VALUES(
     'TwelveData',
    8,
    0,
    'TwelveData API (inactive - still being tested)'
);