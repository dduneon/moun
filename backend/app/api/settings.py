from sqlalchemy import select

from fastapi import APIRouter

from app.core.deps import DbDep, UserDep
from app.models.user_setting import UserSetting
from app.schemas.common import UserSettingPatch, UserSettingResponse

router = APIRouter(prefix="/settings", tags=["settings"])


def _get_or_create(db, user_id: int) -> UserSetting:
    obj = db.scalar(select(UserSetting).where(UserSetting.user_id == user_id))
    if not obj:
        obj = UserSetting(user_id=user_id)
        db.add(obj)
        db.flush()
    return obj


@router.get("", response_model=UserSettingResponse)
def get_settings(db: DbDep, user: UserDep):
    return _get_or_create(db, user.id)


@router.patch("", response_model=UserSettingResponse)
def patch_settings(body: UserSettingPatch, db: DbDep, user: UserDep):
    obj = _get_or_create(db, user.id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj
