import base64
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta
from urllib.parse import parse_qsl, quote

from fastapi import HTTPException, Request
from nacl.exceptions import BadSignatureError
from nacl.signing import VerifyKey
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.ids import new_id
from app.models import Device, DeviceNonce


def hash_secret(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def make_token() -> str:
    return secrets.token_urlsafe(32)


def make_pairing_code() -> str:
    raw = secrets.token_urlsafe(18).replace("-", "").replace("_", "")
    return "-".join([raw[i : i + 4].upper() for i in range(0, 16, 4)])


def b64url_decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding)


def canonical_query(raw_query: bytes) -> str:
    pairs = parse_qsl(raw_query.decode("utf-8"), keep_blank_values=True)
    parts = []
    for key, value in sorted(pairs):
        parts.append(f"{quote(key, safe='')}={quote(value, safe='')}")
    return "&".join(parts)


def canonical_string(
    method: str,
    path: str,
    query: str,
    device_id: str,
    timestamp: str,
    nonce: str,
    body_hash: str,
) -> str:
    return "\n".join([method.upper(), path, query, device_id, timestamp, nonce, body_hash])


async def verify_authenticated_request(request: Request, db: Session) -> Device:
    device_id = request.headers.get("X-Rivet-Device-Id")
    timestamp = request.headers.get("X-Rivet-Timestamp")
    nonce = request.headers.get("X-Rivet-Nonce")
    body_hash = request.headers.get("X-Rivet-Body-SHA256")
    signature = request.headers.get("X-Rivet-Signature")
    auth = request.headers.get("Authorization", "")
    if not all([device_id, timestamp, nonce, body_hash, signature]) or not auth.startswith(
        "Bearer "
    ):
        raise HTTPException(status_code=401, detail="unauthorized")

    device = db.get(Device, device_id)
    if device is None:
        raise HTTPException(status_code=401, detail="unauthorized")
    if device.revoked_at is not None:
        raise HTTPException(status_code=403, detail="device revoked")
    if not hmac.compare_digest(hash_secret(auth.removeprefix("Bearer ")), device.token_hash):
        raise HTTPException(status_code=401, detail="unauthorized")

    try:
        request_time = datetime.utcfromtimestamp(int(timestamp or "0"))
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="unauthorized") from exc
    if abs((datetime.utcnow() - request_time).total_seconds()) > 300:
        raise HTTPException(status_code=401, detail="unauthorized")

    body = await request.body()
    expected_hash = hashlib.sha256(body).hexdigest()
    if expected_hash != body_hash:
        raise HTTPException(status_code=400, detail="body hash mismatch")

    signing_input = canonical_string(
        request.method,
        request.url.path,
        canonical_query(request.scope.get("query_string", b"")),
        device_id or "",
        timestamp or "",
        nonce or "",
        body_hash or "",
    )
    try:
        VerifyKey(b64url_decode(device.public_key)).verify(
            signing_input.encode("utf-8"), b64url_decode(signature or "")
        )
    except (BadSignatureError, ValueError) as exc:
        raise HTTPException(status_code=401, detail="unauthorized") from exc

    db.add(
        DeviceNonce(
            id=new_id(),
            device_id=device.id,
            nonce=nonce or "",
            expires_at=datetime.utcnow() + timedelta(minutes=10),
        )
    )
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=401, detail="unauthorized") from exc

    device.last_seen_at = datetime.utcnow()
    db.add(device)
    db.commit()
    return device
