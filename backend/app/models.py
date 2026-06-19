from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def utcnow() -> datetime:
    return datetime.utcnow()


class Device(Base):
    __tablename__ = "devices"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    display_name: Mapped[str] = mapped_column(String(160))
    public_key: Mapped[str] = mapped_column(Text)
    public_key_algorithm: Mapped[str] = mapped_column(String(32), default="Ed25519")
    token_hash: Mapped[str] = mapped_column(String(128))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class DeviceNonce(Base):
    __tablename__ = "device_nonces"
    __table_args__ = (UniqueConstraint("device_id", "nonce"),)

    id: Mapped[str] = mapped_column(String, primary_key=True)
    device_id: Mapped[str] = mapped_column(ForeignKey("devices.id"))
    nonce: Mapped[str] = mapped_column(String(64))
    seen_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    expires_at: Mapped[datetime] = mapped_column(DateTime)


class PairingCode(Base):
    __tablename__ = "pairing_codes"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    code_hash: Mapped[str] = mapped_column(String(128), unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    claimed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    claimed_device_id: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)


class SettingsVersion(Base):
    __tablename__ = "settings_versions"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    version: Mapped[int] = mapped_column(Integer, unique=True)
    morning_time_local: Mapped[str] = mapped_column(String(5), default="09:00")
    evening_time_local: Mapped[str] = mapped_column(String(5), default="21:00")
    timezone_identifier: Mapped[str] = mapped_column(String(64), default="America/Los_Angeles")
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    theme_mode: Mapped[str] = mapped_column(String(16), default="dark")
    style_example_ego: Mapped[str] = mapped_column(Text, default="")
    style_example_motivational: Mapped[str] = mapped_column(Text, default="")
    summary_memory: Mapped[str] = mapped_column(Text, default="")
    summary_auto_update_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    source_device_id: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class TimelineMessage(Base):
    __tablename__ = "timeline_messages"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    sequence: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    local_date: Mapped[str] = mapped_column(String(10), index=True)
    kind: Mapped[str] = mapped_column(String(16))
    author: Mapped[str] = mapped_column(String(16))
    body: Mapped[str] = mapped_column(Text)
    published_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)
    source_device_id: Mapped[str | None] = mapped_column(String, nullable=True)
    client_request_id: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)
    formulation_session_id: Mapped[str | None] = mapped_column(String, nullable=True)
    metadata_json: Mapped[str] = mapped_column(Text, default="{}")


class ProgressWindow(Base):
    __tablename__ = "progress_windows"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    local_date: Mapped[str] = mapped_column(String(10), unique=True)
    opens_at: Mapped[datetime] = mapped_column(DateTime)
    locks_at: Mapped[datetime] = mapped_column(DateTime)
    status: Mapped[str] = mapped_column(String(16), default="scheduled")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)


class SyncEvent(Base):
    __tablename__ = "sync_events"

    sequence: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    event_type: Mapped[str] = mapped_column(String(32))
    entity_id: Mapped[str] = mapped_column(String)
    entity_table: Mapped[str] = mapped_column(String(64))
    payload_json: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class FormulationSession(Base):
    __tablename__ = "formulation_sessions"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    target_local_date: Mapped[str] = mapped_column(String(10))
    source_progress_window_date: Mapped[str] = mapped_column(String(10))
    status: Mapped[str] = mapped_column(String(32), default="pending")
    model_id: Mapped[str] = mapped_column(String(80))
    settings_version: Mapped[int] = mapped_column(Integer)
    progress_classification: Mapped[str | None] = mapped_column(String(32), nullable=True)
    advice_included: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)


class FormulationStep(Base):
    __tablename__ = "formulation_steps"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    session_id: Mapped[str] = mapped_column(ForeignKey("formulation_sessions.id"))
    step_index: Mapped[int] = mapped_column(Integer)
    role: Mapped[str] = mapped_column(String(16))
    step_type: Mapped[str] = mapped_column(String(32))
    content_json: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
