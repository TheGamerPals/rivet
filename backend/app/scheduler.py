from datetime import datetime, timedelta

from apscheduler.schedulers.background import BackgroundScheduler  # type: ignore[import-untyped]

from app.database import SessionLocal
from app.services import create_no_progress_session, ensure_progress_window


def ensure_today_window() -> None:
    with SessionLocal() as db:
        ensure_progress_window(db, datetime.utcnow().date().isoformat())


def lock_yesterday_window() -> None:
    with SessionLocal() as db:
        source_date = (datetime.utcnow().date() - timedelta(days=1)).isoformat()
        target_date = datetime.utcnow().date().isoformat()
        window = ensure_progress_window(db, source_date)
        if datetime.utcnow() >= window.locks_at and window.status != "finalized":
            window.status = "locked"
            db.add(window)
            create_no_progress_session(db, source_date, target_date)


def build_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler(timezone="UTC")
    scheduler.add_job(ensure_today_window, "interval", minutes=15, id="ensure_progress_window")
    scheduler.add_job(lock_yesterday_window, "interval", minutes=15, id="lock_progress_window")
    return scheduler
