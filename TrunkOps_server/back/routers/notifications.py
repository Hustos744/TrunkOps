"""Routes for notifications.

This router manages the creation and retrieval of notifications
for users, units and assets. Notifications can be marked as
read/unread via their status field. Only authenticated users
may access or create notifications.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user


router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/", response_model=list[schemas.NotificationRead])
def read_notifications(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    # By default, return notifications for the current user only. If user is admin, could allow filtering.
    notifications = db.query(models.Notification).filter(models.Notification.user_id == user.id).offset(skip).limit(limit).all()
    return notifications


@router.post("/", response_model=schemas.NotificationRead)
def create_notification(notification_in: schemas.NotificationCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    # If no user_id set, default to current user
    data = notification_in.dict()
    if not data.get("user_id"):
        data["user_id"] = user.id
    notification = models.Notification(**data)
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


@router.get("/{notification_id}", response_model=schemas.NotificationRead)
def read_notification(notification_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    notification = db.query(models.Notification).filter(models.Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    # Ensure user can only read their own notifications or admin
    if notification.user_id and notification.user_id != user.id and user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return notification


@router.put("/{notification_id}", response_model=schemas.NotificationRead)
def update_notification(notification_id: int, notification_in: schemas.NotificationCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    notification = db.query(models.Notification).filter(models.Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    # Only allow updating your own notifications or if admin
    if notification.user_id and notification.user_id != user.id and user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    for key, value in notification_in.dict().items():
        setattr(notification, key, value)
    db.commit()
    db.refresh(notification)
    return notification