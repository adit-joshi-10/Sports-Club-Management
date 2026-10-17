"""Request/response shapes for authentication."""
from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=1, max_length=72)


class UserOut(BaseModel):
    user_id: int
    email: str
    role: str
    full_name: str | None = None
    # password_hash is deliberately NOT here, so it can never leak


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserOut
