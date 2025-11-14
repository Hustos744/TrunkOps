"""Authentication routes for the TrunkOps FastAPI backend.

This module defines endpoints for user registration and login.
It uses a simple token-based mechanism stored in the database via
the `user_session` table. Passwords are hashed with SHA-256 for
demonstration purposes (not recommended for production use).
"""

from __future__ import annotations

import secrets
import hashlib
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

from sqlalchemy.orm import Session

from .. import database, models, schemas


router = APIRouter(prefix="/auth", tags=["auth"])


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def get_password_hash(password: str) -> str:
    """Return a SHA-256 hash of the given password.

    Warning: This hashing method is for demonstration only. In
    production, use a stronger algorithm such as bcrypt or Argon2.
    """
    return hashlib.sha256(password.encode()).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return get_password_hash(plain_password) == hashed_password


def authenticate_user(db: Session, username: str, password: str) -> Optional[models.AppUser]:
    user = db.query(models.AppUser).filter(models.AppUser.username == username).first()
    if not user:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user


@router.post("/register", response_model=schemas.UserRead)
def register(user_in: schemas.UserCreate, db: Session = Depends(database.get_db)):
    # Check if username already exists
    existing = db.query(models.AppUser).filter(models.AppUser.username == user_in.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already registered")
    # Hash password and create user
    hashed_password = get_password_hash(user_in.password)
    user = models.AppUser(
        username=user_in.username,
        password_hash=hashed_password,
        role=user_in.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    # Create empty settings for the user
    settings = models.UserSettings(user_id=user.id, theme_mode="LIGHT")
    db.add(settings)
    db.commit()
    return user


@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    # Generate random token and expiry (e.g., 1 hour)
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=1)
    # Store session
    session = models.UserSession(token=token, user_id=user.id, expires_at=expires_at)
    db.add(session)
    user.last_login = datetime.utcnow()
    db.commit()
    return schemas.Token(access_token=token)


def get_current_user(db: Session = Depends(database.get_db), token: str = Depends(oauth2_scheme)) -> models.AppUser:
    """Dependency to retrieve the current authenticated user.

    It checks whether the provided token exists and is not expired.
    """
    session = db.query(models.UserSession).filter(models.UserSession.token == token).first()
    if not session or session.expires_at < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user = db.query(models.AppUser).filter(models.AppUser.id == session.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
