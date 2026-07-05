from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class SpaceCreate(BaseModel):
    name: str
    base_day: int = 1


class SpaceUpdate(BaseModel):
    name: str


class SpaceResponse(BaseModel):
    id: int
    name: str
    base_day: int
    created_by_user_id: int
    member_count: int
    model_config = {"from_attributes": True}


class SpaceInviteResponse(BaseModel):
    token: str
    url: str
    expires_at: datetime


class SpaceInvitePreview(BaseModel):
    space_id: int
    space_name: str
    member_count: int
    valid: bool


class SpaceMemberResponse(BaseModel):
    user_id: int
    name: str
    email: str | None
    joined_at: datetime
    is_owner: bool
