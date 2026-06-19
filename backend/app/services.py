import json
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import HTTPException
from sqlalchemy import desc, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import get_settings
from app.ids import new_id
from app.models import (
    Device,
    FormulationSession,
    PairingCode,
    ProgressWindow,
    SettingsVersion,
    SyncEvent,
    TimelineMessage,
)
from app.schemas import (
    ProgressWindowPayload,
    SettingsPayload,
    SettingsUpdateRequest,
    SyncEventPayload,
    TimelineMessagePayload,
)
from app.security import hash_secret, make_token


def server_time() -> datetime:
    return datetime.utcnow()


def current_settings(db: Session) -> SettingsVersion:
    row = db.scalar(select(SettingsVersion).order_by(desc(SettingsVersion.version)).limit(1))
    if row is None:
        row = SettingsVersion(id=new_id(), version=1)
        db.add(row)
        db.commit()
        db.refresh(row)
    return row


def settings_payload(row: SettingsVersion) -> SettingsPayload:
    return SettingsPayload(
        version=row.version,
        morning_time_local=row.morning_time_local,
        evening_time_local=row.evening_time_local,
        timezone_identifier=row.timezone_identifier,
        notifications_enabled=row.notifications_enabled,
        theme_mode=row.theme_mode,  # type: ignore[arg-type]
        style_example_ego=row.style_example_ego,
        style_example_motivational=row.style_example_motivational,
        summary_memory=row.summary_memory,
        summary_auto_update_enabled=row.summary_auto_update_enabled,
    )


def message_payload(row: TimelineMessage) -> TimelineMessagePayload:
    return TimelineMessagePayload(
        id=row.id,
        sequence=row.sequence,
        local_date=row.local_date,
        kind=row.kind,  # type: ignore[arg-type]
        author=row.author,  # type: ignore[arg-type]
        body=row.body,
        published_at=row.published_at,
        created_at=row.created_at,
        source_device_id=row.source_device_id,
        client_request_id=row.client_request_id,
        formulation_session_id=row.formulation_session_id,
        metadata_json=row.metadata_json,
    )


def window_payload(row: ProgressWindow | None) -> ProgressWindowPayload | None:
    if row is None:
        return None
    return ProgressWindowPayload(
        id=row.id,
        local_date=row.local_date,
        opens_at=row.opens_at,
        locks_at=row.locks_at,
        status=row.status,
    )


def emit_event(
    db: Session, event_type: str, entity_table: str, entity_id: str, payload: dict
) -> int:
    event = SyncEvent(
        event_type=event_type,
        entity_table=entity_table,
        entity_id=entity_id,
        payload_json=json.dumps(payload, default=str),
    )
    db.add(event)
    db.flush()
    return event.sequence


def latest_cursor(db: Session) -> int:
    return db.scalar(select(func.max(SyncEvent.sequence))) or 0


def next_message_sequence(db: Session) -> int:
    return (db.scalar(select(func.max(TimelineMessage.sequence))) or 0) + 1


def sync_events_after(db: Session, cursor: int) -> list[SyncEventPayload]:
    rows = db.scalars(
        select(SyncEvent).where(SyncEvent.sequence > cursor).order_by(SyncEvent.sequence)
    ).all()
    return [
        SyncEventPayload(
            sequence=row.sequence,
            event_type=row.event_type,
            entity_id=row.entity_id,
            entity_table=row.entity_table,
            payload=json.loads(row.payload_json),
            created_at=row.created_at,
        )
        for row in rows
    ]


def create_device_from_pairing(
    db: Session, pairing_code: str, display_name: str, public_key: str
) -> tuple[Device, str]:
    pairing = db.scalar(
        select(PairingCode)
        .where(PairingCode.code_hash == hash_secret(pairing_code))
        .where(PairingCode.claimed_at.is_(None))
    )
    if pairing is None or pairing.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="invalid or expired pairing code")
    token = make_token()
    device = Device(
        id=new_id(),
        display_name=display_name,
        public_key=public_key,
        token_hash=hash_secret(token),
    )
    pairing.claimed_at = datetime.utcnow()
    pairing.claimed_device_id = device.id
    db.add(device)
    db.add(pairing)
    emit_event(
        db, "device_changed", "devices", device.id, {"id": device.id, "display_name": display_name}
    )
    db.commit()
    return device, token


def ensure_progress_window(db: Session, local_date: str) -> ProgressWindow:
    existing = db.scalar(select(ProgressWindow).where(ProgressWindow.local_date == local_date))
    if existing is not None:
        return existing
    settings = current_settings(db)
    tz = ZoneInfo(settings.timezone_identifier)
    day = datetime.fromisoformat(local_date).date()
    open_hour, open_minute = [int(part) for part in settings.evening_time_local.split(":")]
    morning_hour, morning_minute = [int(part) for part in settings.morning_time_local.split(":")]
    opens_at = (
        datetime(day.year, day.month, day.day, open_hour, open_minute, tzinfo=tz)
        .astimezone(ZoneInfo("UTC"))
        .replace(tzinfo=None)
    )
    next_day = day + timedelta(days=1)
    locks_at = (
        (
            datetime(
                next_day.year, next_day.month, next_day.day, morning_hour, morning_minute, tzinfo=tz
            )
            - timedelta(hours=1)
        )
        .astimezone(ZoneInfo("UTC"))
        .replace(tzinfo=None)
    )
    row = ProgressWindow(
        id=new_id(),
        local_date=local_date,
        opens_at=opens_at,
        locks_at=locks_at,
        status="scheduled",
    )
    db.add(row)
    payload = window_payload(row)
    assert payload is not None
    emit_event(
        db,
        "window_changed",
        "progress_windows",
        row.id,
        payload.model_dump(mode="json"),
    )
    db.commit()
    db.refresh(row)
    return row


def accept_progress(
    db: Session, device: Device, client_request_id: str, local_date: str, body: str
) -> tuple[TimelineMessage, ProgressWindow | None, int]:
    existing = db.scalar(
        select(TimelineMessage).where(TimelineMessage.client_request_id == client_request_id)
    )
    if existing is not None:
        return existing, ensure_progress_window(db, local_date), latest_cursor(db)
    window = ensure_progress_window(db, local_date)
    now = datetime.utcnow()
    if now >= window.locks_at or window.status in {"locked", "finalized"}:
        raise HTTPException(status_code=409, detail="Too late for briefing")
    if now < window.opens_at:
        raise HTTPException(status_code=409, detail="Progress window is not open")
    if window.status != "open":
        window.status = "open"
        db.add(window)
    message = TimelineMessage(
        id=new_id(),
        sequence=next_message_sequence(db),
        local_date=local_date,
        kind="progress",
        author="human",
        body=body.strip(),
        published_at=now,
        source_device_id=device.id,
        client_request_id=client_request_id,
    )
    db.add(message)
    db.flush()
    cursor = emit_event(
        db,
        "message_created",
        "timeline_messages",
        message.id,
        message_payload(message).model_dump(mode="json"),
    )
    db.commit()
    db.refresh(message)
    return message, window, cursor


def update_settings(
    db: Session, device: Device, payload: SettingsUpdateRequest
) -> tuple[SettingsVersion, int]:
    current = current_settings(db)
    base_version = payload.base_version
    if base_version != current.version:
        raise HTTPException(status_code=409, detail="settings conflict")
    next_row = SettingsVersion(
        id=new_id(),
        version=current.version + 1,
        morning_time_local=payload.morning_time_local,
        evening_time_local=payload.evening_time_local,
        timezone_identifier=payload.timezone_identifier,
        notifications_enabled=payload.notifications_enabled,
        theme_mode=payload.theme_mode,
        style_example_ego=payload.style_example_ego,
        style_example_motivational=payload.style_example_motivational,
        summary_memory=payload.summary_memory,
        summary_auto_update_enabled=payload.summary_auto_update_enabled,
        source_device_id=device.id,
    )
    db.add(next_row)
    db.flush()
    cursor = emit_event(
        db,
        "settings_changed",
        "settings_versions",
        next_row.id,
        settings_payload(next_row).model_dump(mode="json"),
    )
    db.commit()
    db.refresh(next_row)
    return next_row, cursor


def day_messages(db: Session, local_date: str) -> list[TimelineMessagePayload]:
    rows = db.scalars(
        select(TimelineMessage)
        .where(TimelineMessage.local_date == local_date)
        .where(TimelineMessage.published_at.is_not(None))
        .order_by(TimelineMessage.created_at)
    ).all()
    return [message_payload(row) for row in rows]


def diagnostics_data(db: Session) -> tuple[str, int]:
    db_path = get_settings().database_url.rsplit("/", 1)[-1]
    return Path(db_path).name, latest_cursor(db)


def create_pairing_code_record(db: Session, code: str, ttl_minutes: int) -> None:
    db.add(
        PairingCode(
            id=new_id(),
            code_hash=hash_secret(code),
            expires_at=datetime.utcnow() + timedelta(minutes=ttl_minutes),
        )
    )
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise


def create_no_progress_session(
    db: Session, source_date: str, target_date: str
) -> FormulationSession:
    settings = current_settings(db)
    session = FormulationSession(
        id=new_id(),
        target_local_date=target_date,
        source_progress_window_date=source_date,
        status="pending",
        model_id=get_settings().model_id,
        settings_version=settings.version,
        progress_classification="no_progress",
    )
    db.add(session)
    emit_event(db, "session_changed", "formulation_sessions", session.id, {"id": session.id})
    db.commit()
    return session
