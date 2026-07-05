from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import func, select

from app.core.config import settings
from app.core.deps import DbDep, SpaceDep, SpaceOwnerDep, UserDep
from app.models.space import Space, SpaceInvite, SpaceMember
from app.models.space_finance import SpaceCategory
from app.models.user import User
from app.schemas.space import (
    SpaceCreate,
    SpaceInvitePreview,
    SpaceInviteResponse,
    SpaceMemberResponse,
    SpaceResponse,
    SpaceUpdate,
)

router = APIRouter(prefix="/spaces", tags=["spaces"])

_DEFAULT_SPACE_CATEGORIES = [
    "식비", "교통", "쇼핑", "문화", "의료",
    "통신", "카페", "여행", "구독", "기타",
]


def _member_count(db: DbDep, space_id: int) -> int:
    return db.scalar(select(func.count()).select_from(SpaceMember).where(SpaceMember.space_id == space_id)) or 0


def _to_response(db: DbDep, space: Space) -> SpaceResponse:
    return SpaceResponse(
        id=space.id,
        name=space.name,
        base_day=space.base_day,
        created_by_user_id=space.created_by_user_id,
        member_count=_member_count(db, space.id),
    )


@router.post("", response_model=SpaceResponse, status_code=status.HTTP_201_CREATED)
def create_space(body: SpaceCreate, db: DbDep, user: UserDep):
    space = Space(name=body.name, base_day=body.base_day, created_by_user_id=user.id)
    db.add(space)
    db.flush()
    db.add(SpaceMember(space_id=space.id, user_id=user.id))
    for name in _DEFAULT_SPACE_CATEGORIES:
        db.add(SpaceCategory(space_id=space.id, name=name))
    db.commit()
    db.refresh(space)
    return _to_response(db, space)


@router.get("", response_model=list[SpaceResponse])
def list_my_spaces(db: DbDep, user: UserDep):
    spaces = db.scalars(
        select(Space).join(SpaceMember, SpaceMember.space_id == Space.id).where(SpaceMember.user_id == user.id)
    ).all()
    return [_to_response(db, s) for s in spaces]


@router.get("/{space_id}", response_model=SpaceResponse)
def get_space(space: SpaceDep, db: DbDep):
    return _to_response(db, space)


@router.patch("/{space_id}", response_model=SpaceResponse)
def update_space(body: SpaceUpdate, space: SpaceDep, db: DbDep):
    space.name = body.name
    db.commit()
    db.refresh(space)
    return _to_response(db, space)


@router.delete("/{space_id}/members/me", status_code=status.HTTP_204_NO_CONTENT)
def leave_space(space: SpaceDep, db: DbDep, user: UserDep):
    membership = db.scalar(
        select(SpaceMember).where(SpaceMember.space_id == space.id, SpaceMember.user_id == user.id)
    )
    db.delete(membership)
    db.commit()


@router.get("/{space_id}/members", response_model=list[SpaceMemberResponse])
def list_members(space: SpaceDep, db: DbDep):
    rows = db.execute(
        select(SpaceMember, User)
        .join(User, User.id == SpaceMember.user_id)
        .where(SpaceMember.space_id == space.id)
        .order_by(SpaceMember.joined_at)
    ).all()
    return [
        SpaceMemberResponse(
            user_id=member.user_id,
            name=member_user.name,
            email=member_user.email,
            joined_at=member.joined_at,
            is_owner=member.user_id == space.created_by_user_id,
        )
        for member, member_user in rows
    ]


@router.delete("/{space_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(user_id: int, space: SpaceOwnerDep, db: DbDep):
    if user_id == space.created_by_user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="관리자는 제외할 수 없습니다")

    membership = db.scalar(
        select(SpaceMember).where(SpaceMember.space_id == space.id, SpaceMember.user_id == user_id)
    )
    if membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="멤버를 찾을 수 없습니다")
    db.delete(membership)
    db.commit()


@router.post("/{space_id}/invites", response_model=SpaceInviteResponse, status_code=status.HTTP_201_CREATED)
def create_invite(space: SpaceDep, db: DbDep, user: UserDep):
    token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(hours=settings.SPACE_INVITE_EXPIRE_HOURS)
    invite = SpaceInvite(
        space_id=space.id,
        token=token,
        created_by_user_id=user.id,
        expires_at=expires_at,
    )
    db.add(invite)
    db.commit()
    return SpaceInviteResponse(
        token=token,
        url=f"{settings.FRONTEND_BASE_URL}/invite/{token}",
        expires_at=expires_at,
    )


@router.get("/invites/{token}", response_model=SpaceInvitePreview)
def preview_invite(token: str, db: DbDep):
    invite = db.scalar(select(SpaceInvite).where(SpaceInvite.token == token))
    if invite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="유효하지 않은 초대 링크입니다")

    space = db.scalar(select(Space).where(Space.id == invite.space_id))
    valid = (
        not invite.revoked
        and invite.expires_at > datetime.now(timezone.utc).replace(tzinfo=None)
        and (invite.max_uses is None or invite.use_count < invite.max_uses)
    )
    return SpaceInvitePreview(
        space_id=space.id,
        space_name=space.name,
        member_count=_member_count(db, space.id),
        valid=valid,
    )


@router.post("/invites/{token}/accept", response_model=SpaceResponse)
def accept_invite(token: str, db: DbDep, user: UserDep):
    invite = db.scalar(select(SpaceInvite).where(SpaceInvite.token == token))
    if invite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="유효하지 않은 초대 링크입니다")
    if invite.revoked or invite.expires_at <= datetime.now(timezone.utc).replace(tzinfo=None):
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="만료되었거나 취소된 초대 링크입니다")
    if invite.max_uses is not None and invite.use_count >= invite.max_uses:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="초대 링크 사용 횟수를 초과했습니다")

    space = db.scalar(select(Space).where(Space.id == invite.space_id))

    existing = db.scalar(
        select(SpaceMember).where(SpaceMember.space_id == space.id, SpaceMember.user_id == user.id)
    )
    if existing is None:
        db.add(SpaceMember(space_id=space.id, user_id=user.id))
        invite.use_count += 1
        db.commit()
        db.refresh(space)

    return _to_response(db, space)
