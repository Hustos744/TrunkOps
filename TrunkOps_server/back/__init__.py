"""Backend package for the TrunkOps FastAPI server.

This package contains the FastAPI application, database models,
schemas, CRUD utilities and routers for handling various entities
such as users, units, device models, network nodes and more.

The server uses SQLAlchemy to connect to a PostgreSQL database and
automatically creates the required tables on startup. Routers
provide RESTful endpoints for performing CRUD operations on the
defined models.
"""
