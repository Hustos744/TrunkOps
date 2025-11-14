"""Database configuration and session management.

This module configures a SQLAlchemy engine and sessionmaker for
connecting to a PostgreSQL database. The connection string can
be provided via the `DATABASE_URL` environment variable; if not
specified, a default local connection is used. On application
startup, the tables are created if they do not already exist.
"""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Generator, Optional

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


# Read database URL from environment or use a sensible default.
# Example format: postgresql+psycopg2://user:password@localhost:5432/trunkops_db
DATABASE_URL: str = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:123@localhost:5432/trunkops_db",
)

# Create the SQLAlchemy engine. `echo=True` can be enabled for SQL logging.
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# SessionLocal is a factory that will create new Session objects
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@contextmanager
def get_db() -> Generator:
    """Provide a transactional scope around a series of operations.

    Yields a SQLAlchemy session and ensures that the session is
    properly closed after use.

    Usage:

    ```python
    with get_db() as db:
        # perform DB operations
        ...
    ```
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def init_db() -> None:
    """Initialize the database by creating all tables.

    This function should be called on application startup to ensure
    that all tables defined in `models.py` are present in the
    configured database.
    """
    # Import models here to ensure they are registered before create_all
    from . import models  # noqa: F401

    models.Base.metadata.create_all(bind=engine)
