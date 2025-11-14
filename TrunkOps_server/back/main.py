"""Entry point for the TrunkOps FastAPI backend.

This module creates the FastAPI application, initializes the
database and includes all routers. To run the server locally,
execute `uvicorn TrunkOps_server.back.main:app --reload` from the
project root. The database URL can be configured via the
`DATABASE_URL` environment variable.
"""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import database
from .routers import auth, units, devices, nodes, assets, maintenance, notifications, audit, settings

# Initialize FastAPI app
app = FastAPI(title="TrunkOps Backend", version="0.1.0")

# Add CORS middleware to allow frontend applications to access API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    """Initialize the database on application startup."""
    database.init_db()


# Include routers
app.include_router(auth.router)
app.include_router(units.router)
app.include_router(devices.router)
app.include_router(nodes.router)
app.include_router(assets.router)
app.include_router(maintenance.router)
app.include_router(notifications.router)
app.include_router(audit.router)
app.include_router(settings.router)