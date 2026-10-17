"""Request/response shapes for sports."""
from pydantic import BaseModel, ConfigDict, Field, field_validator

ICON_PATTERN = r"^[a-z_]{1,30}$"


class SportCreate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    name: str = Field(min_length=2, max_length=80)
    description: str | None = Field(default=None, max_length=500)
    icon_key: str = Field(default="generic", pattern=ICON_PATTERN)


class SportUpdate(BaseModel):
    """PATCH body: send only the fields you want to change."""
    model_config = ConfigDict(str_strip_whitespace=True)

    name: str | None = Field(default=None, min_length=2, max_length=80)
    description: str | None = Field(default=None, max_length=500)
    icon_key: str | None = Field(default=None, pattern=ICON_PATTERN)

    @field_validator("name", "icon_key")
    @classmethod
    def not_null(cls, value):
        if value is None:
            raise ValueError("must not be null")
        return value


class SportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    sport_id: int
    name: str
    description: str | None
    icon_key: str
