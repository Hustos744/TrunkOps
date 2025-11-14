"""Routes for device models.

Allows CRUD operations on `DeviceModel` instances. Only authenticated
users may create new models. Listing and reading is open to
authenticated users.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/device-models", tags=["device-models"])


@router.get("/", response_model=list[schemas.DeviceModelRead])
def read_device_models(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    devices = db.query(models.DeviceModel).offset(skip).limit(limit).all()
    return devices


@router.post("/", response_model=schemas.DeviceModelRead)
def create_device_model(device_in: schemas.DeviceModelCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    device = models.DeviceModel(**device_in.dict())
    db.add(device)
    db.commit()
    db.refresh(device)
    return device


@router.get("/{device_id}", response_model=schemas.DeviceModelRead)
def read_device_model(device_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    device = db.query(models.DeviceModel).filter(models.DeviceModel.id == device_id).first()
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device model not found")
    return device
