"""Routes for network nodes and coverage zones.

Provides endpoints to create and read network nodes and their associated
coverage zones. Coverage zones store the geometry (as GeoJSON/WKT)
and percentage values for stable, degraded and critical areas. Only
authenticated users may create entries.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/nodes", tags=["nodes"])


@router.get("/", response_model=list[schemas.NetworkNodeRead])
def read_nodes(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    nodes = db.query(models.NetworkNode).offset(skip).limit(limit).all()
    return nodes


@router.post("/", response_model=schemas.NetworkNodeRead)
def create_node(node_in: schemas.NetworkNodeCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    node = models.NetworkNode(**node_in.dict())
    db.add(node)
    db.commit()
    db.refresh(node)
    return node


@router.get("/{node_id}", response_model=schemas.NetworkNodeRead)
def read_node(node_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    node = db.query(models.NetworkNode).filter(models.NetworkNode.id == node_id).first()
    if not node:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Node not found")
    return node


@router.get("/{node_id}/coverage", response_model=list[schemas.CoverageZoneRead])
def read_coverage_zones(node_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    zones = db.query(models.CoverageZone).filter(models.CoverageZone.node_id == node_id).all()
    return zones


@router.post("/{node_id}/coverage", response_model=schemas.CoverageZoneRead)
def create_coverage_zone(node_id: int, zone_in: schemas.CoverageZoneCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    # ensure zone_in.node_id matches path
    if zone_in.node_id != node_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Node ID mismatch")
    # ensure node exists
    node = db.query(models.NetworkNode).filter(models.NetworkNode.id == node_id).first()
    if not node:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Node not found")
    zone = models.CoverageZone(**zone_in.dict())
    db.add(zone)
    db.commit()
    db.refresh(zone)
    return zone
