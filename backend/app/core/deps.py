from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import decode_token
from app.db.base import SessionLocal
from app.db.redis import get_redis
from app.models.space import Space, SpaceMember
from app.models.user import User

bearer = HTTPBearer()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="인증 정보가 유효하지 않습니다",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(credentials.credentials)
        if payload.get("type") != "access":
            raise exc
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise exc

    user = db.scalar(select(User).where(User.id == user_id, User.is_active.is_(True)))
    if user is None:
        raise exc
    return user


DbDep = Annotated[Session, Depends(get_db)]
UserDep = Annotated[User, Depends(get_current_user)]
RedisDep = Annotated[Redis, Depends(get_redis)]


def get_space_membership(space_id: int, db: DbDep, user: UserDep) -> Space:
    space = db.scalar(select(Space).where(Space.id == space_id))
    if space is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="스페이스를 찾을 수 없습니다")

    is_member = db.scalar(
        select(SpaceMember).where(SpaceMember.space_id == space_id, SpaceMember.user_id == user.id)
    )
    if is_member is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="스페이스 멤버가 아닙니다")

    return space


SpaceDep = Annotated[Space, Depends(get_space_membership)]


def get_space_owner(space_id: int, db: DbDep, user: UserDep) -> Space:
    space = get_space_membership(space_id, db, user)
    if space.created_by_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="스페이스 관리자만 가능합니다")
    return space


SpaceOwnerDep = Annotated[Space, Depends(get_space_owner)]
