import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.db.base import Base
from app.models.user import User
from app.models.user_setting import UserSetting
import app.models  # noqa: F401


@pytest.fixture(scope="function")
def db():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    Base.metadata.drop_all(engine)


@pytest.fixture
def user(db: Session) -> User:
    u = User(email="test@example.com")
    db.add(u)
    db.flush()
    setting = UserSetting(user_id=u.id, salary_day=21, payday_adjustment="prev_business", holiday_country="KR")
    db.add(setting)
    db.flush()
    return u


@pytest.fixture
def user_salary10(db: Session) -> User:
    """salary_day=10인 사용자."""
    u = User(email="test10@example.com")
    db.add(u)
    db.flush()
    setting = UserSetting(user_id=u.id, salary_day=10, payday_adjustment="prev_business", holiday_country="KR")
    db.add(setting)
    db.flush()
    return u
