import pandas as pd
import pyodbc
import yfinance as yf

TICKER = "AAPL"
START_DATE = "2026-04-01"
END_DATE = "2026-04-10"
SOURCE = "YahooFinance"
BATCH_ID = 1

SQL_SERVER = r"localhost\SQLEXPRESS"
SQL_DATABASE = "FinancialMetrics_dev"
SQL_DRIVER = "ODBC Driver 17 for SQL Server"


def download_yahoo_prices(ticker: str, start_date: str, end_date: str) -> pd.DataFrame:
    data = yf.download(
        ticker,
        start=start_date,
        end=end_date,
        auto_adjust=False
    )
    return data


def transform_prices(data: pd.DataFrame, ticker: str, source: str, batch_id: int) -> pd.DataFrame:
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
    data["source"] = source
    data["batch_id"] = batch_id

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

    return data


def get_sql_connection() -> pyodbc.Connection:
    connection_string = f"""
    DRIVER={{{SQL_DRIVER}}};
    SERVER={SQL_SERVER};
    DATABASE={SQL_DATABASE};
    Trusted_Connection=yes;
    """

    conn = pyodbc.connect(connection_string)

    return conn


def insert_staging_rows(conn: pyodbc.Connection, data: pd.DataFrame) -> None:
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


def execute_upsert_procedure(conn: pyodbc.Connection) -> None:
    # Execute staging-to-core upsert procedure
    cursor = conn.cursor()

    cursor.execute("EXEC core.upsert_prices_daily;")

    conn.commit()


def main() -> None:
    # Download market data
    data = download_yahoo_prices(TICKER, START_DATE, END_DATE)

    # Transform data into staging schema
    data = transform_prices(data, TICKER, SOURCE, BATCH_ID)

    # Connect to SQL Server
    conn = get_sql_connection()
    print("SQL Server connection successful.")

    # Load staging data
    insert_staging_rows(conn, data)
    print(f"{len(data)} rows inserted into staging.")

    # Execute staging-to-core upsert
    execute_upsert_procedure(conn)
    print("Upsert procedure executed successfully.")

    conn.close()


if __name__ == "__main__":
    main()