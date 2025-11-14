"""Routes for maintenance tasks and logs.

This router exposes endpoints to manage maintenance tasks
and associated log entries. Only authenticated users may
create or modify tasks and logs. Tasks can be assigned
to units or assets as needed.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import database, models, schemas
from .auth import get_current_user


router = APIRouter(prefix="/maintenance", tags=["maintenance"])


@router.get("/tasks", response_model=list[schemas.MaintenanceTaskRead])
def read_tasks(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    tasks = db.query(models.MaintenanceTask).offset(skip).limit(limit).all()
    return tasks


@router.post("/tasks", response_model=schemas.MaintenanceTaskRead)
def create_task(task_in: schemas.MaintenanceTaskCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    task = models.MaintenanceTask(**task_in.dict())
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.get("/tasks/{task_id}", response_model=schemas.MaintenanceTaskRead)
def read_task(task_id: int, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    task = db.query(models.MaintenanceTask).filter(models.MaintenanceTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Maintenance task not found")
    return task


@router.get("/tasks/{task_id}/logs", response_model=list[schemas.MaintenanceTaskLogRead])
def read_task_logs(task_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    task = db.query(models.MaintenanceTask).filter(models.MaintenanceTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Maintenance task not found")
    logs = db.query(models.MaintenanceTaskLog).filter(models.MaintenanceTaskLog.task_id == task_id).offset(skip).limit(limit).all()
    return logs


@router.post("/tasks/{task_id}/logs", response_model=schemas.MaintenanceTaskLogRead)
def create_task_log(task_id: int, log_in: schemas.MaintenanceTaskLogCreate, db: Session = Depends(database.get_db), user: models.AppUser = Depends(get_current_user)):
    if log_in.task_id != task_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Task ID mismatch")
    task = db.query(models.MaintenanceTask).filter(models.MaintenanceTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Maintenance task not found")
    log = models.MaintenanceTaskLog(**log_in.dict())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log