"""Pydantic schemas for request and response validation.

These dataclasses mirror the SQLAlchemy models defined in
`models.py` but are used for data validation and serialization via
FastAPI. Schemas for user registration/login, units, device models,
network nodes, coverage zones and authentication tokens are
included. Relationships are flattened to IDs where appropriate.
"""

from __future__ import annotations

from datetime import datetime, date
from typing import Optional

from pydantic import BaseModel, Field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    username: Optional[str] = None


# User schemas
class UserBase(BaseModel):
    username: str


class UserCreate(UserBase):
    password: str = Field(min_length=6)
    role: str = "operator"


class UserRead(UserBase):
    id: int
    role: str
    last_login: Optional[datetime]
    class Config:
        orm_mode = True


# Unit type schemas
class UnitTypeBase(BaseModel):
    title: str
    description: Optional[str] = None


class UnitTypeCreate(UnitTypeBase):
    pass


class UnitTypeRead(UnitTypeBase):
    id: int
    class Config:
        orm_mode = True


# Unit schemas
class UnitBase(BaseModel):
    name: str
    type_id: int
    area: Optional[str] = None
    status: str
    status_label: Optional[str] = None
    activity: Optional[str] = None


class UnitCreate(UnitBase):
    pass


class UnitRead(UnitBase):
    id: int
    last_updated: datetime
    class Config:
        orm_mode = True


# Device model schemas
class DeviceModelBase(BaseModel):
    model_name: str
    manufacturer: Optional[str] = None
    freq_min_mhz: Optional[float] = None
    freq_max_mhz: Optional[float] = None
    output_power_w: Optional[float] = None
    antenna_gain_db: Optional[float] = None
    sensitivity_dbm: Optional[float] = None
    notes: Optional[str] = None


class DeviceModelCreate(DeviceModelBase):
    pass


class DeviceModelRead(DeviceModelBase):
    id: int
    class Config:
        orm_mode = True


# Network node schemas
class NetworkNodeBase(BaseModel):
    name: str
    unit_id: Optional[int] = None
    device_model_id: int
    latitude: float
    longitude: float
    altitude_m: Optional[float] = None
    status: Optional[str] = None
    description: Optional[str] = None
    frequency_mhz: Optional[float] = None
    erp_w: Optional[float] = None
    antenna_height_m: Optional[float] = None


class NetworkNodeCreate(NetworkNodeBase):
    pass


class NetworkNodeRead(NetworkNodeBase):
    id: int
    created_at: datetime
    updated_at: datetime
    class Config:
        orm_mode = True


# Coverage zone schemas
class CoverageZoneBase(BaseModel):
    geometry: str
    stable_percent: Optional[float] = None
    degraded_percent: Optional[float] = None
    critical_percent: Optional[float] = None
    algorithm: str


class CoverageZoneCreate(CoverageZoneBase):
    node_id: int


class CoverageZoneRead(CoverageZoneBase):
    id: int
    node_id: int
    generated_at: datetime
    class Config:
        orm_mode = True


# Asset type schemas
class AssetTypeBase(BaseModel):
    title: str
    description: Optional[str] = None


class AssetTypeCreate(AssetTypeBase):
    pass


class AssetTypeRead(AssetTypeBase):
    id: int
    class Config:
        orm_mode = True


# Asset schemas
class AssetBase(BaseModel):
    inventory_number: str
    asset_type_id: int
    model: Optional[str] = None
    unit_id: Optional[int] = None
    status: Optional[str] = None
    location: Optional[str] = None
    last_check_date: Optional[date] = None
    remarks: Optional[str] = None


class AssetCreate(AssetBase):
    pass


class AssetRead(AssetBase):
    id: int
    class Config:
        orm_mode = True

# Maintenance task schemas
class MaintenanceTaskBase(BaseModel):
    title: str
    planned_date: Optional[date] = None
    status: Optional[str] = None
    status_label: Optional[str] = None
    description: Optional[str] = None
    unit_id: Optional[int] = None
    asset_id: Optional[int] = None


class MaintenanceTaskCreate(MaintenanceTaskBase):
    pass


class MaintenanceTaskRead(MaintenanceTaskBase):
    id: int
    created_at: datetime
    updated_at: datetime
    class Config:
        orm_mode = True


class MaintenanceTaskLogBase(BaseModel):
    action: str
    timestamp: Optional[datetime] = None
    comment: Optional[str] = None
    performed_by: Optional[int] = None


class MaintenanceTaskLogCreate(MaintenanceTaskLogBase):
    task_id: int


class MaintenanceTaskLogRead(MaintenanceTaskLogBase):
    id: int
    task_id: int
    class Config:
        orm_mode = True


# Notification schemas
class NotificationBase(BaseModel):
    type: Optional[str] = None
    icon: Optional[str] = None
    title: str
    description: Optional[str] = None
    timestamp: Optional[datetime] = None
    status: Optional[str] = None
    unit_id: Optional[int] = None
    asset_id: Optional[int] = None
    user_id: Optional[int] = None


class NotificationCreate(NotificationBase):
    pass


class NotificationRead(NotificationBase):
    id: int
    timestamp: datetime
    class Config:
        orm_mode = True


# Audit log schema
class AuditLogRead(BaseModel):
    id: int
    timestamp: datetime
    user_id: Optional[int] = None
    action: str
    status: str
    details: Optional[str] = None
    class Config:
        orm_mode = True


# User settings schemas
class UserSettingsBase(BaseModel):
    notifications_enabled: Optional[bool] = None
    auto_update_enabled: Optional[bool] = None
    theme_mode: Optional[str] = None


class UserSettingsUpdate(UserSettingsBase):
    pass


class UserSettingsRead(UserSettingsBase):
    user_id: int
    cache_updated_at: Optional[datetime] = None
    class Config:
        orm_mode = True