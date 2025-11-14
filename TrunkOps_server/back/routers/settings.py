"""Routes for user settings.

This router provides endpoints for retrieving and updating the
current user's settings such as notification preferences,
auto-update enablement and theme mode.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from datetime import datetime
from .auth import get_current_user


router = APIRouter(prefix="/user-settings", tags=["user-settings"])


@router.get("/", response_model=schemas.UserSettingsRead)
def read_user_settings(db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    settings = db.query(models.UserSettings).filter(models.UserSettings.user_id == user.id).first()
    if not settings:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Settings not found")
    return settings


@router.put("/", response_model=schemas.UserSettingsRead)
def update_user_settings(settings_in: schemas.UserSettingsUpdate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    settings = db.query(models.UserSettings).filter(models.UserSettings.user_id == user.id).first()
    if not settings:
        # Create settings if not exists
        settings = models.UserSettings(user_id=user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    for key, value in settings_in.dict(exclude_unset=True).items():
        setattr(settings, key, value)
    settings.cache_updated_at = datetime.utcnow()
    db.commit()
    db.refresh(settings)
    return settings