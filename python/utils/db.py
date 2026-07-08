import os
from pathlib import Path

import pyodbc
from dotenv import load_dotenv


def load_environment() -> None:
    project_root = Path(__file__).resolve().parents[2]
    load_dotenv(project_root / ".env")


def get_sql_connection() -> pyodbc.Connection:
    load_environment()

    sql_server = os.getenv("SQL_SERVER")
    sql_database = os.getenv("SQL_DATABASE")
    sql_driver = os.getenv("SQL_DRIVER")

    connection_string = f"""
    DRIVER={{{sql_driver}}};
    SERVER={sql_server};
    DATABASE={sql_database};
    Trusted_Connection=yes;
    """

    conn = pyodbc.connect(connection_string)

    return conn