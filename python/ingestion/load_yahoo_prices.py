import os

import pandas as pd
import pyodbc
import yfinance as yf

from dotenv import load_dotenv

load_dotenv()

TICKERS = [
    ticker.strip()
    for ticker in os.getenv("TICKERS", "").split(",")
    if ticker.strip()
]
START_DATE = os.getenv("START_DATE")
END_DATE = os.getenv("END_DATE")
SOURCE = os.getenv("SOURCE")

SQL_SERVER = os.getenv("SQL_SERVER")
SQL_DATABASE = os.getenv("SQL_DATABASE")
SQL_DRIVER = os.getenv("SQL_DRIVER")


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


def create_batch_run(conn: pyodbc.Connection, source: str) -> int:
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO log.batch_run (
            source,
            [status]
        )
        OUTPUT INSERTED.batch_id
        VALUES (?, 'STARTED');
        """,
        source
    )

    batch_id = int(cursor.fetchone()[0])
    conn.commit()

    return batch_id


def finish_batch_run(conn: pyodbc.Connection, batch_id: int, rows_inserted: int) -> None:
    cursor = conn.cursor()

    cursor.execute(
        """
        UPDATE log.batch_run
        SET
            [status] = 'SUCCESS',
            finished_at = SYSDATETIME(),
            rows_inserted = ?
        WHERE batch_id = ?;
        """,
        rows_inserted,
        batch_id
    )

    conn.commit()


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
    # Connect to SQL Server
    conn = get_sql_connection()
    print("SQL Server connection successful.")

    # Create batch run
    batch_id = create_batch_run(conn, SOURCE)
    print(f"Created batch run {batch_id}.")

    # Download and transform market data
    frames = []

    for ticker in TICKERS:
        raw_data = download_yahoo_prices(ticker, START_DATE, END_DATE)
        transformed_data = transform_prices(raw_data, ticker, SOURCE, batch_id)
        frames.append(transformed_data)
    
    data = pd.concat(frames, ignore_index=True)

    # Load staging data
    insert_staging_rows(conn, data)
    print(f"{len(data)} rows inserted into staging.")

    # Execute staging-to-core upsert
    execute_upsert_procedure(conn)
    print("Upsert procedure executed successfully.")

    # Finish batch run
    finish_batch_run(conn, batch_id, len(data))
    print(f"Batch run {batch_id} finished successfully.")

    conn.close()


if __name__ == "__main__":
    main()