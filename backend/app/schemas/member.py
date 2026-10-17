"""Request/response shapes for members."""
from datetime import date
from typing import Annotated

from pydantic import BaseModel, Field, StringConstraints, field_validator

EMAIL_PATTERN = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
PHONE_PATTERN = r"^\+?[0-9]{7,15}$"

Email = Annotated[str, StringConstraints(strip_whitespace=True, max_length=255, pattern=EMAIL_PATTERN)]
FullName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=120)]
Phone = Annotated[str, StringConstraints(strip_whitespace=True, pattern=PHONE_PATTERN)]


def _dob_not_future(value: date | None) -> date | None:
    if value is not None and value > date.today():
        raise ValueError("date_of_birth cannot be in the future")
    return value


class MemberCreate(BaseModel):
    email: Email
    password: str = Field(min_length=8, max_length=72)
    full_name: FullName
    phone: Phone | None = None
    date_of_birth: date | None = None

    @field_validator("date_of_birth")
    @classmethod
    def dob_check(cls, value):
        return _dob_not_future(value)


class MemberUpdate(BaseModel):
    """PATCH body: send only the fields you want to change."""
    full_name: FullName | None = None
    phone: Phone | None = None
    date_of_birth: date | None = None

    @field_validator("full_name")
    @classmethod
    def name_not_null(cls, value):
        if value is None:
            raise ValueError("must not be null")
        return value

    @field_validator("date_of_birth")
    @classmethod
    def dob_check(cls, value):
        return _dob_not_future(value)


class MemberOut(BaseModel):
    member_id: int
    user_id: int
    email: str
    full_name: str
    phone: str | None
    date_of_birth: date | None
    joined_on: date
    # no password fields here, so a hash can never leak