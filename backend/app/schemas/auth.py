from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_id: str = "default"  # 멀티디바이스 구분용


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: int
    email: str | None
    name: str
    is_active: bool
    salary_day: int = 1

    model_config = {"from_attributes": True}


class UserPatch(BaseModel):
    salary_day: int | None = None


class KakaoLoginRequest(BaseModel):
    kakao_access_token: str
    device_id: str = "mobile"


class KakaoTokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    is_new_user: bool
