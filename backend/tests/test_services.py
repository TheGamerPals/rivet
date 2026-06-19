from datetime import datetime, timedelta

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.ids import new_id
from app.models import Device, ProgressWindow
from app.security import hash_secret
from app.services import accept_progress, current_settings, ensure_progress_window


@pytest.fixture()
def db():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, expire_on_commit=False)
    with Session() as session:
        yield session


def device() -> Device:
    return Device(
        id=new_id(),
        display_name="test",
        public_key="public",
        token_hash=hash_secret("token"),
    )


def test_current_settings_defaults(db) -> None:
    settings = current_settings(db)
    assert settings.version == 1
    assert settings.morning_time_local == "09:00"
    assert settings.theme_mode == "dark"


def test_progress_idempotency(db) -> None:
    d = device()
    db.add(d)
    now = datetime.utcnow()
    db.add(
        ProgressWindow(
            id=new_id(),
            local_date="2026-06-19",
            opens_at=now - timedelta(minutes=5),
            locks_at=now + timedelta(hours=2),
            status="open",
        )
    )
    db.commit()
    first, _, _ = accept_progress(db, d, "req-1", "2026-06-19", "built the backend")
    second, _, _ = accept_progress(db, d, "req-1", "2026-06-19", "built the backend")
    assert first.id == second.id


def test_late_progress_rejected(db) -> None:
    d = device()
    db.add(d)
    now = datetime.utcnow()
    db.add(
        ProgressWindow(
            id=new_id(),
            local_date="2026-06-19",
            opens_at=now - timedelta(hours=3),
            locks_at=now - timedelta(minutes=1),
            status="locked",
        )
    )
    db.commit()
    with pytest.raises(HTTPException):
        accept_progress(db, d, "req-2", "2026-06-19", "too late")


def test_ensure_progress_window_creates_window(db) -> None:
    window = ensure_progress_window(db, "2026-06-19")
    assert window.local_date == "2026-06-19"
    assert window.locks_at > window.opens_at
