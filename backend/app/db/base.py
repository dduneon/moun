from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,   # 쿼리 전 커넥션 생존 확인, 끊긴 커넥션은 자동 교체
    pool_recycle=3600,    # DB의 idle timeout(wait_timeout)보다 짧게 주기적으로 재생성
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass
