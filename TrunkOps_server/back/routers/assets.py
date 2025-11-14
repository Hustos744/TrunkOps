"""Routes for assets and asset types.

Allows CRUD operations on assets and asset types. Authentication is
required for creating entries; listing and reading requires
authentication as well.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/assets", tags=["assets"])


@router.get("/types", response_model=list[schemas.AssetTypeRead])
def read_asset_types(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    types = db.query(models.AssetType).offset(skip).limit(limit).all()
    return types


@router.post("/types", response_model=schemas.AssetTypeRead)
def create_asset_type(type_in: schemas.AssetTypeCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    asset_type = models.AssetType(**type_in.dict())
    db.add(asset_type)
    db.commit()
    db.refresh(asset_type)
    return asset_type


@router.get("/", response_model=list[schemas.AssetRead])
def read_assets(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    assets = db.query(models.Asset).offset(skip).limit(limit).all()
    return assets


@router.post("/", response_model=schemas.AssetRead)
def create_asset(asset_in: schemas.AssetCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    asset = models.Asset(**asset_in.dict())
    db.add(asset)
    db.commit()
    db.refresh(asset)
    return asset


@router.get("/{asset_id}", response_model=schemas.AssetRead)
def read_asset(asset_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    asset = db.query(models.Asset).filter(models.Asset.id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asset not found")
    return asset
