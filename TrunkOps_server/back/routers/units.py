"""Routes for unit types and units.

Provides CRUD endpoints for unit types and units. Authentication is
required for creating and modifying entries. Listing and reading
entries is open to authenticated users.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/units", tags=["units"])


@router.get("/types", response_model=list[schemas.UnitTypeRead])
def read_unit_types(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db)):
    types = db.query(models.UnitType).offset(skip).limit(limit).all()
    return types


@router.post("/types", response_model=schemas.UnitTypeRead)
def create_unit_type(type_in: schemas.UnitTypeCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    unit_type = models.UnitType(**type_in.dict())
    db.add(unit_type)
    db.commit()
    db.refresh(unit_type)
    return unit_type


@router.get("/", response_model=list[schemas.UnitRead])
def read_units(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    units = db.query(models.Unit).offset(skip).limit(limit).all()
    return units


@router.post("/", response_model=schemas.UnitRead)
def create_unit(unit_in: schemas.UnitCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    unit = models.Unit(**unit_in.dict())
    db.add(unit)
    db.commit()
    db.refresh(unit)
    return unit


@router.get("/{unit_id}", response_model=schemas.UnitRead)
def read_unit(unit_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    unit = db.query(models.Unit).filter(models.Unit.id == unit_id).first()
    if not unit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unit not found")
    return unit
