
"""Request/response shapes for coaches."""
from typing import Annotated

from pydantic import (
    BaseModel,
    Field,
    StringConstraints,
    field_validator,
)

EMAIL_PATTERN = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
PHONE_PATTERN = r"^\+?[0-9]{7,15}$"

Email = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        max_length=255,
        pattern=EMAIL_PATTERN,
    ),
]

FullName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=2,
        max_length=120,
    ),
]

Phone = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        pattern=PHONE_PATTERN,
    ),
]

Specialization = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        min_length=2,
        max_length=100,
    ),
]


class CoachCreate(BaseModel):
    """Request body for creating a coach and login account."""

    email: Email
    password: str = Field(min_length=8, max_length=72)
    full_name: FullName
    phone: Phone | None = None
    specialization: Specialization | None = None


class CoachUpdate(BaseModel):
    """PATCH body: only supplied fields are changed."""

    full_name: FullName | None = None
    phone: Phone | None = None
    specialization: Specialization | None = None

    @field_validator("full_name")
    @classmethod
    def name_not_null(cls, value):
        """Prevent a required coach name from being explicitly set to null."""
        if value is None:
            raise ValueError("must not be null")
        return value


class CoachOut(BaseModel):
    """Response body for coach details; never exposes password data."""

    coach_id: int
    user_id: int
    email: str
    full_name: str
    phone: str | None
    specialization: str | None
