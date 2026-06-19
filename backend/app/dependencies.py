from fastapi import Request
from sqlalchemy.orm import Session

from app.models import Device
from app.security import verify_authenticated_request


async def authenticated_device(request: Request, db: Session) -> Device:
    return await verify_authenticated_request(request, db)
