"""SQLAlchemy model definitions for the TrunkOps backend.

The models in this module mirror the PostgreSQL schema defined in
`postgres_schema.md`. They define ORM classes for users, units,
device models, network nodes, coverage zones, assets, maintenance
tasks, audit logs, notifications, user settings and auxiliary
tables. Relationships are defined where appropriate to enable
joined queries and cascade deletions.
"""

from __future__ import annotations

from datetime import datetime, date
from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Date,
    Numeric,
    ForeignKey,
    Boolean,
    Text,
)
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()


class AppUser(Base):
    __tablename__ = "app_user"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)
    last_login = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    sessions = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    settings = relationship("UserSettings", back_populates="user", uselist=False, cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="user")
    maintenance_logs = relationship("MaintenanceTaskLog", back_populates="performed_by_user")
    notifications = relationship("Notification", back_populates="user")
    asset_checks = relationship("AssetCheckHistory", back_populates="performed_by_user")


class UserSession(Base):
    __tablename__ = "user_session"
    token = Column(String(255), primary_key=True)
    user_id = Column(Integer, ForeignKey("app_user.id", ondelete="CASCADE"), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

    user = relationship("AppUser", back_populates="sessions")


class UnitType(Base):
    __tablename__ = "unit_type"
    id = Column(Integer, primary_key=True)
    title = Column(String(100), nullable=False)
    description = Column(Text)

    units = relationship("Unit", back_populates="type")


class Unit(Base):
    __tablename__ = "unit"
    id = Column(Integer, primary_key=True)
    name = Column(String(150), nullable=False)
    type_id = Column(Integer, ForeignKey("unit_type.id"), nullable=False)
    area = Column(String(100))
    status = Column(String(20), nullable=False)
    status_label = Column(String(100))
    activity = Column(String(50))
    last_updated = Column(DateTime(timezone=True), default=datetime.utcnow)

    type = relationship("UnitType", back_populates="units")
    assets = relationship("Asset", back_populates="unit")
    nodes = relationship("NetworkNode", back_populates="unit")
    maintenance_tasks = relationship("MaintenanceTask", back_populates="unit")
    notifications = relationship("Notification", back_populates="unit")


class DeviceModel(Base):
    __tablename__ = "device_model"
    id = Column(Integer, primary_key=True)
    model_name = Column(String(100), nullable=False)
    manufacturer = Column(String(100))
    freq_min_mhz = Column(Numeric(10, 2))
    freq_max_mhz = Column(Numeric(10, 2))
    output_power_w = Column(Numeric(10, 2))
    antenna_gain_db = Column(Numeric(5, 2))
    sensitivity_dbm = Column(Numeric(10, 2))
    notes = Column(Text)

    nodes = relationship("NetworkNode", back_populates="device_model")


class NetworkNode(Base):
    __tablename__ = "network_node"
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    unit_id = Column(Integer, ForeignKey("unit.id"))
    device_model_id = Column(Integer, ForeignKey("device_model.id"), nullable=False)
    latitude = Column(Numeric(10, 6), nullable=False)
    longitude = Column(Numeric(10, 6), nullable=False)
    altitude_m = Column(Numeric(10, 2))
    status = Column(String(20))
    description = Column(Text)
    frequency_mhz = Column(Numeric(10, 2))
    erp_w = Column(Numeric(10, 2))
    antenna_height_m = Column(Numeric(10, 2))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    unit = relationship("Unit", back_populates="nodes")
    device_model = relationship("DeviceModel", back_populates="nodes")
    coverage_zones = relationship("CoverageZone", back_populates="node", cascade="all, delete-orphan")
    status_history = relationship("NodeStatusHistory", back_populates="node", cascade="all, delete-orphan")


class CoverageZone(Base):
    __tablename__ = "coverage_zone"
    id = Column(Integer, primary_key=True)
    node_id = Column(Integer, ForeignKey("network_node.id", ondelete="CASCADE"), nullable=False)
    geometry = Column(Text, nullable=False)  # store GeoJSON or WKT for simplicity
    stable_percent = Column(Numeric(5, 2))
    degraded_percent = Column(Numeric(5, 2))
    critical_percent = Column(Numeric(5, 2))
    generated_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    algorithm = Column(String(100), nullable=False)

    node = relationship("NetworkNode", back_populates="coverage_zones")


class NodeStatusHistory(Base):
    __tablename__ = "node_status_history"
    id = Column(Integer, primary_key=True)
    node_id = Column(Integer, ForeignKey("network_node.id", ondelete="CASCADE"), nullable=False)
    timestamp = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    status = Column(String(20), nullable=False)
    details = Column(Text)

    node = relationship("NetworkNode", back_populates="status_history")


class AssetType(Base):
    __tablename__ = "asset_type"
    id = Column(Integer, primary_key=True)
    title = Column(String(100), nullable=False)
    description = Column(Text)

    assets = relationship("Asset", back_populates="asset_type")


class Asset(Base):
    __tablename__ = "asset"
    id = Column(Integer, primary_key=True)
    inventory_number = Column(String(50), unique=True, nullable=False)
    asset_type_id = Column(Integer, ForeignKey("asset_type.id"), nullable=False)
    model = Column(String(100))
    unit_id = Column(Integer, ForeignKey("unit.id"))
    status = Column(String(20))
    location = Column(String(150))
    last_check_date = Column(Date)
    remarks = Column(Text)

    asset_type = relationship("AssetType", back_populates="assets")
    unit = relationship("Unit", back_populates="assets")
    check_history = relationship("AssetCheckHistory", back_populates="asset", cascade="all, delete-orphan")
    maintenance_tasks = relationship("MaintenanceTask", back_populates="asset")
    notifications = relationship("Notification", back_populates="asset")


class AssetCheckHistory(Base):
    __tablename__ = "asset_check_history"
    id = Column(Integer, primary_key=True)
    asset_id = Column(Integer, ForeignKey("asset.id", ondelete="CASCADE"), nullable=False)
    check_date = Column(Date, nullable=False)
    result = Column(String(10), nullable=False)
    notes = Column(Text)
    performed_by = Column(Integer, ForeignKey("app_user.id"))

    asset = relationship("Asset", back_populates="check_history")
    performed_by_user = relationship("AppUser", back_populates="asset_checks")


class MaintenanceTask(Base):
    __tablename__ = "maintenance_task"
    id = Column(Integer, primary_key=True)
    title = Column(String(150), nullable=False)
    planned_date = Column(Date)
    status = Column(String(20))
    status_label = Column(String(100))
    description = Column(Text)
    unit_id = Column(Integer, ForeignKey("unit.id"))
    asset_id = Column(Integer, ForeignKey("asset.id"))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    unit = relationship("Unit", back_populates="maintenance_tasks")
    asset = relationship("Asset", back_populates="maintenance_tasks")
    logs = relationship("MaintenanceTaskLog", back_populates="task", cascade="all, delete-orphan")


class MaintenanceTaskLog(Base):
    __tablename__ = "maintenance_task_log"
    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("maintenance_task.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(50), nullable=False)
    timestamp = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    comment = Column(Text)
    performed_by = Column(Integer, ForeignKey("app_user.id"))

    task = relationship("MaintenanceTask", back_populates="logs")
    performed_by_user = relationship("AppUser", back_populates="maintenance_logs")


class AuditLog(Base):
    __tablename__ = "audit_log"
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    user_id = Column(Integer, ForeignKey("app_user.id"))
    action = Column(Text, nullable=False)
    status = Column(String(20), nullable=False)
    details = Column(Text)

    user = relationship("AppUser", back_populates="audit_logs")


class Notification(Base):
    __tablename__ = "notification"
    id = Column(Integer, primary_key=True)
    type = Column(String(50))
    icon = Column(String(100))
    title = Column(String(150), nullable=False)
    description = Column(Text)
    timestamp = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    status = Column(String(10))
    unit_id = Column(Integer, ForeignKey("unit.id"))
    asset_id = Column(Integer, ForeignKey("asset.id"))
    user_id = Column(Integer, ForeignKey("app_user.id"))

    unit = relationship("Unit", back_populates="notifications")
    asset = relationship("Asset", back_populates="notifications")
    user = relationship("AppUser", back_populates="notifications")


class UserSettings(Base):
    __tablename__ = "user_settings"
    user_id = Column(Integer, ForeignKey("app_user.id", ondelete="CASCADE"), primary_key=True)
    notifications_enabled = Column(Boolean, default=True)
    auto_update_enabled = Column(Boolean, default=True)
    theme_mode = Column(String(10))
    cache_updated_at = Column(DateTime(timezone=True))

    user = relationship("AppUser", back_populates="settings")


class StatusDefinition(Base):
    __tablename__ = "status_definition"
    id = Column(Integer, primary_key=True)
    category = Column(String(50), nullable=False)
    code = Column(String(20), nullable=False)
    label = Column(String(100), nullable=False)
    color = Column(String(7))
