from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator


class ApiEnvelope(BaseModel):
    server_time: datetime
    request_id: str


class SettingsPayload(BaseModel):
    version: int
    morning_time_local: str = "09:00"
    evening_time_local: str = "21:00"
    timezone_identifier: str = "America/Los_Angeles"
    notifications_enabled: bool = True
    theme_mode: Literal["dark", "light", "system"] = "dark"
    style_example_ego: str = ""
    style_example_motivational: str = ""
    summary_memory: str = ""
    summary_auto_update_enabled: bool = False


class PairClaimRequest(BaseModel):
    pairing_code: str
    device_display_name: str = Field(min_length=1, max_length=160)
    device_public_key: str = Field(min_length=32)


class PairClaimResponse(ApiEnvelope):
    device_id: str
    device_token: str
    initial_cursor: int
    settings: SettingsPayload


class TimelineMessagePayload(BaseModel):
    id: str
    sequence: int
    local_date: str
    kind: Literal["briefing", "checkin", "progress"]
    author: Literal["app", "human"]
    body: str
    published_at: datetime | None
    created_at: datetime
    source_device_id: str | None = None
    client_request_id: str | None = None
    formulation_session_id: str | None = None
    metadata_json: str = "{}"


class ProgressWindowPayload(BaseModel):
    id: str
    local_date: str
    opens_at: datetime
    locks_at: datetime
    status: str


class SyncEventPayload(BaseModel):
    sequence: int
    event_type: str
    entity_id: str
    entity_table: str
    payload: dict[str, Any]
    created_at: datetime


class SyncResponse(ApiEnvelope):
    cursor: int
    events: list[SyncEventPayload]
    settings: SettingsPayload
    progress_window: ProgressWindowPayload | None


class ProgressRequest(BaseModel):
    client_request_id: str = Field(min_length=8, max_length=80)
    local_date: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    body: str = Field(max_length=8000)

    @field_validator("body")
    @classmethod
    def body_not_empty(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("progress body is required")
        return stripped


class ProgressResponse(ApiEnvelope):
    message: TimelineMessagePayload
    progress_window: ProgressWindowPayload | None
    cursor_after: int


class SettingsUpdateRequest(BaseModel):
    base_version: int
    morning_time_local: str
    evening_time_local: str
    timezone_identifier: str
    notifications_enabled: bool
    theme_mode: Literal["dark", "light", "system"]
    style_example_ego: str = Field(max_length=4000)
    style_example_motivational: str = Field(max_length=4000)
    summary_memory: str
    summary_auto_update_enabled: bool

    @field_validator("summary_memory")
    @classmethod
    def summary_word_limit(cls, value: str) -> str:
        if len(value.split()) > 350:
            raise ValueError("summary must be 350 words or fewer")
        return value


class SettingsUpdateResponse(ApiEnvelope):
    settings: SettingsPayload
    affected_windows: list[str]
    cursor_after: int


class DayResponse(ApiEnvelope):
    date: str
    messages: list[TimelineMessagePayload]
    progress_window: ProgressWindowPayload | None
    formulation_status: str | None


class DiagnosticsResponse(ApiEnvelope):
    backend_version: str
    database_path: str
    current_settings_version: int
    latest_cursor: int
    scheduler_status: str
    last_mistral_call_at: datetime | None
    pending_jobs: dict[str, int]
