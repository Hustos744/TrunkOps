"""Routes for audit logs.

This router provides endpoints to view audit logs recorded in the
system. Creating audit logs is generally performed internally
within the application whenever an action occurs; external
clients typically only need to read logs. Access to audit logs
may be restricted to administrators.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user


router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("/logs", response_model=list[schemas.AuditLogRead])
def read_audit_logs(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    # Only admin role may view all logs; others see only their own.
    query = db.query(models.AuditLog)
    if user.role != "admin":
        query = query.filter(models.AuditLog.user_id == user.id)
    logs = query.order_by(models.AuditLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs