import yfinance as yf
import pyodbc

ticker = "AAPL"

data = yf.download(
    ticker,
    start="2026-04-01",
    end="2026-04-10",
    auto_adjust=False
)

# Flatten MultiIndex columns
data.columns = data.columns.get_level_values(0)
data.columns.name = None

# Convert index into normal column
data = data.reset_index()

# Rename columns to match staging table
data = data.rename(
    columns={
        "Date": "trade_date",
        "Open": "open",
        "High": "high",
        "Low": "low",
        "Close": "close",
        "Adj Close": "adj_close",
        "Volume": "volume"
    }
)

# Add pipeline metadata columns
data["symbol"] = ticker
data["source"] = "YahooFinance"
data["batch_id"] = 1

# Reorder columns
data = data[
    [
        "batch_id",
        "symbol",
        "trade_date",
        "open",
        "high",
        "low",
        "close",
        "adj_close",
        "volume",
        "source"
    ]
]

print(data.head())
print(data.columns)
print(data.dtypes)

connection_string = """
DRIVER={ODBC Driver 17 for SQL Server};
SERVER={localhost\\SQLEXPRESS};
DATABASE=FinancialMetrics_dev;
Trusted_Connection=yes;
"""

conn = pyodbc.connect(connection_string)

print("SQL Server connection successful.")

cursor = conn.cursor()

for _, row in data.iterrows():
    cursor.execute(
        """
        INSERT INTO stg.prices_daily (
            batch_id,
            symbol,
            trade_date,
            [open],
            high,
            low,
            [close],
            adj_close,
            volume,
            source
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        int(row["batch_id"]),
        row["symbol"],
        row["trade_date"],
        float(row["open"]),
        float(row["high"]),
        float(row["low"]),
        float(row["close"]),
        float(row["adj_close"]),
        int(row["volume"]),
        row["source"]
    )

conn.commit()

print(f"{len(data)} rows inserted successfully.")

# Execute staging-to-core upsert procedure
cursor.execute("EXEC core.upsert_prices_daily;")
conn.commit()

print("Upsert procedure executed successfully.")