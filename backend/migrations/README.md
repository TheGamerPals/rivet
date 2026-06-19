Alembic migrations live here.

Initial implementation currently creates tables through SQLAlchemy metadata during app startup for local development. Before production deployment, generate the initial Alembic revision from `app.models` and apply it on `autopersonal`.
