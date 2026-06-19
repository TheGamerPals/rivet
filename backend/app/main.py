from uuid import uuid4

from fastapi import Depends, FastAPI, Request
from sqlalchemy.orm import Session

from app.database import get_db, init_db
from app.schemas import (
    DayResponse,
    DiagnosticsResponse,
    PairClaimRequest,
    PairClaimResponse,
    ProgressRequest,
    ProgressResponse,
    SettingsUpdateRequest,
    SettingsUpdateResponse,
    SyncResponse,
)
from app.security import verify_authenticated_request
from app.services import (
    accept_progress,
    create_device_from_pairing,
    current_settings,
    day_messages,
    diagnostics_data,
    ensure_progress_window,
    latest_cursor,
    server_time,
    settings_payload,
    sync_events_after,
    update_settings,
    window_payload,
)

app = FastAPI(title="Rivet backend", version="0.1.0")


@app.on_event("startup")
def startup() -> None:
    init_db()


def request_id() -> str:
    return str(uuid4())


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/pair/claim", response_model=PairClaimResponse)
def pair_claim(payload: PairClaimRequest, db: Session = Depends(get_db)) -> PairClaimResponse:
    device, token = create_device_from_pairing(
        db, payload.pairing_code, payload.device_display_name, payload.device_public_key
    )
    return PairClaimResponse(
        request_id=request_id(),
        server_time=server_time(),
        device_id=device.id,
        device_token=token,
        initial_cursor=latest_cursor(db),
        settings=settings_payload(current_settings(db)),
    )


@app.get("/v1/sync", response_model=SyncResponse)
async def sync(request: Request, cursor: int = 0, db: Session = Depends(get_db)) -> SyncResponse:
    await verify_authenticated_request(request, db)
    current = current_settings(db)
    window = ensure_progress_window(db, server_time().date().isoformat())
    events = sync_events_after(db, cursor)
    return SyncResponse(
        request_id=request_id(),
        server_time=server_time(),
        cursor=latest_cursor(db),
        events=events,
        settings=settings_payload(current),
        progress_window=window_payload(window),
    )


@app.post("/v1/progress", response_model=ProgressResponse)
async def progress(
    request: Request, payload: ProgressRequest, db: Session = Depends(get_db)
) -> ProgressResponse:
    device = await verify_authenticated_request(request, db)
    message, window, cursor = accept_progress(
        db, device, payload.client_request_id, payload.local_date, payload.body
    )
    from app.services import message_payload

    return ProgressResponse(
        request_id=request_id(),
        server_time=server_time(),
        message=message_payload(message),
        progress_window=window_payload(window),
        cursor_after=cursor,
    )


@app.put("/v1/settings", response_model=SettingsUpdateResponse)
async def settings_update(
    request: Request, payload: SettingsUpdateRequest, db: Session = Depends(get_db)
) -> SettingsUpdateResponse:
    device = await verify_authenticated_request(request, db)
    settings_row, cursor = update_settings(db, device, payload)
    return SettingsUpdateResponse(
        request_id=request_id(),
        server_time=server_time(),
        settings=settings_payload(settings_row),
        affected_windows=[],
        cursor_after=cursor,
    )


@app.get("/v1/day/{local_date}", response_model=DayResponse)
async def day(local_date: str, request: Request, db: Session = Depends(get_db)) -> DayResponse:
    await verify_authenticated_request(request, db)
    window = ensure_progress_window(db, local_date)
    return DayResponse(
        request_id=request_id(),
        server_time=server_time(),
        date=local_date,
        messages=day_messages(db, local_date),
        progress_window=window_payload(window),
        formulation_status=None,
    )


@app.get("/v1/diagnostics", response_model=DiagnosticsResponse)
async def diagnostics(request: Request, db: Session = Depends(get_db)) -> DiagnosticsResponse:
    await verify_authenticated_request(request, db)
    database_path, cursor = diagnostics_data(db)
    return DiagnosticsResponse(
        request_id=request_id(),
        server_time=server_time(),
        backend_version="0.1.0",
        database_path=database_path,
        current_settings_version=current_settings(db).version,
        latest_cursor=cursor,
        scheduler_status="configured",
        last_mistral_call_at=None,
        pending_jobs={},
    )
