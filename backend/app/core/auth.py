from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt
from redis import Redis

from app.core.config import settings

# Redis key prefix
_REFRESH_KEY = "refresh:{jti}"
_RATE_KEY = "rate:login:{ip}"


# ── 비밀번호 ─────────────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


# ── JWT ──────────────────────────────────────────────────────────────────────

def _make_token(payload: dict, expire: timedelta) -> str:
    now = datetime.now(timezone.utc)
    data = {**payload, "iat": now, "exp": now + expire}
    return jwt.encode(data, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_access_token(user_id: int) -> str:
    return _make_token(
        {"sub": str(user_id), "type": "access"},
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(user_id: int, device_id: str) -> tuple[str, str]:
    """(token, jti) 반환. jti로 Redis key를 관리해 멀티디바이스 지원."""
    jti = str(uuid.uuid4())
    token = _make_token(
        {"sub": str(user_id), "type": "refresh", "jti": jti, "did": device_id},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return token, jti


def decode_token(token: str) -> dict:
    """검증 실패 시 JWTError 발생."""
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


# ── Redis refresh token 저장소 ────────────────────────────────────────────────

def _refresh_key(jti: str) -> str:
    return _REFRESH_KEY.format(jti=jti)


def store_refresh_token(redis: Redis, user_id: int, jti: str) -> None:
    ttl = settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400
    redis.setex(_refresh_key(jti), ttl, str(user_id))


def validate_refresh_token_in_store(redis: Redis, jti: str, user_id: int) -> bool:
    stored = redis.get(_refresh_key(jti))
    return stored == str(user_id)


def revoke_refresh_token(redis: Redis, jti: str) -> None:
    redis.delete(_refresh_key(jti))


# ── Rate limiting ─────────────────────────────────────────────────────────────

def _rate_key(ip: str) -> str:
    return _RATE_KEY.format(ip=ip)


def check_login_rate_limit(redis: Redis, ip: str) -> bool:
    """True이면 허용, False이면 차단."""
    key = _rate_key(ip)
    count = redis.incr(key)
    if count == 1:
        redis.expire(key, settings.LOGIN_RATE_LIMIT_WINDOW)
    return count <= settings.LOGIN_RATE_LIMIT_MAX


def reset_login_rate_limit(redis: Redis, ip: str) -> None:
    redis.delete(_rate_key(ip))
