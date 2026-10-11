"""Opening the SQLite database."""

import os
import sqlite3
from pathlib import Path

SCHEMA = Path(__file__).with_name("schema.sql")


def db_path():
    return os.environ.get("STEPQUEST_DB", "stepquest.db")


def connect():
    conn = sqlite3.connect(db_path(), check_same_thread=False)
    conn.row_factory = sqlite3.Row  # rows act like dicts: row["username"]
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    with connect() as conn:
        conn.executescript(SCHEMA.read_text())


def get_db():
    """FastAPI dependency: one connection per request, saved at the end."""
    conn = connect()
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()
