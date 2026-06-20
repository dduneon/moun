from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request, status
from jose import JWTError
from sqlalchemy import select

from app.core.auth import (
    check_login_rate_limit,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    reset_login_rate_limit,
    revoke_refresh_token,
    store_refresh_token,
    validate_refresh_token_in_store,
    verify_password,
)
from app.core.deps import DbDep, RedisDep, UserDep
from app.models.user import User
from app.schemas.auth import (
    AccessTokenResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: DbDep):
    if db.scalar(select(User).where(User.email == body.email)):
        raise HTTPException(status_code=409, detail="이미 사용 중인 이메일입니다")
    user = User(
        email=body.email,
        hashed_password=hash_password(body.password),
        name=body.name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, request: Request, db: DbDep, redis: RedisDep):
    ip = request.client.host if request.client else "unknown"

    if not check_login_rate_limit(redis, ip):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="로그인 시도 횟수를 초과했습니다. 잠시 후 다시 시도해주세요",
        )

    user = db.scalar(select(User).where(User.email == body.email, User.is_active.is_(True)))
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="이메일 또는 비밀번호가 올바르지 않습니다",
        )

    reset_login_rate_limit(redis, ip)
    access_token = create_access_token(user.id)
    refresh_token, jti = create_refresh_token(user.id, body.device_id)
    store_refresh_token(redis, user.id, jti)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=AccessTokenResponse)
def refresh(body: RefreshRequest, redis: RedisDep):
    exc = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="유효하지 않은 refresh token입니다")
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise exc
        user_id = int(payload["sub"])
        jti = payload["jti"]
    except (JWTError, KeyError, ValueError):
        raise exc

    if not validate_refresh_token_in_store(redis, jti, user_id):
        raise exc

    return AccessTokenResponse(access_token=create_access_token(user_id))


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(body: RefreshRequest, redis: RedisDep):
    try:
        payload = decode_token(body.refresh_token)
        jti = payload.get("jti")
        if jti:
            revoke_refresh_token(redis, jti)
    except JWTError:
        pass  # 이미 만료된 토큰도 로그아웃 성공으로 처리


@router.get("/me", response_model=UserResponse)
def me(current_user: UserDep):
    return current_user
