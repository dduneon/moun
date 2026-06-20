import pytest
import fakeredis
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

import app.models  # noqa: F401 — register all models before any fixture runs
from app.db.base import Base
from app.db.redis import get_redis
from app.core.deps import get_db
from app.main import app as fastapi_app
from app.models.user import User
from app.models.user_setting import UserSetting


# ── Unit-test fixtures (no HTTP) ──────────────────────────────────────────────

@pytest.fixture(scope="function")
def db():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    Base.metadata.drop_all(engine)


@pytest.fixture
def user(db: Session) -> User:
    u = User(email="test@example.com", hashed_password="x", name="테스터")
    db.add(u)
    db.flush()
    setting = UserSetting(user_id=u.id, salary_day=21, payday_adjustment="prev_business", holiday_country="KR")
    db.add(setting)
    db.flush()
    return u


@pytest.fixture
def user_salary10(db: Session) -> User:
    u = User(email="test10@example.com", hashed_password="x", name="테스터10")
    db.add(u)
    db.flush()
    setting = UserSetting(user_id=u.id, salary_day=10, payday_adjustment="prev_business", holiday_country="KR")
    db.add(setting)
    db.flush()
    return u


# ── API integration fixtures ──────────────────────────────────────────────────

@pytest.fixture(scope="function")
def client():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    redis_mock = fakeredis.FakeRedis(decode_responses=True)

    def override_db():
        with Session(engine) as session:
            yield session

    def override_redis():
        return redis_mock

    fastapi_app.dependency_overrides[get_db] = override_db
    fastapi_app.dependency_overrides[get_redis] = override_redis

    with TestClient(fastapi_app) as c:
        yield c

    fastapi_app.dependency_overrides.clear()
    Base.metadata.drop_all(engine)
