"""Request/response shapes for registrations, schedules and attendance."""
from datetime import date, datetime, time
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

Status = Literal["present", "late", "absent"]


class RegistrationCreate(BaseModel):
    sport_id: int


class RegistrationOut(BaseModel):
    registration_id: int
    member_id: int
    member_name: str
    sport_id: int
    sport_name: str
    registered_at: datetime


class ScheduleCreate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    sport_id: int
    coach_id: int
    session_date: date
    start_time: time
    end_time: time
    venue: str = Field(min_length=2, max_length=100)
    notes: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def times_in_order(self):
        if self.end_time <= self.start_time:
            raise ValueError("end_time must be after start_time")
        return self


class ScheduleUpdate(BaseModel):
    """PATCH body: send only the fields you want to change."""
    model_config = ConfigDict(str_strip_whitespace=True)

    sport_id: int | None = None
    coach_id: int | None = None
    session_date: date | None = None
    start_time: time | None = None
    end_time: time | None = None
    venue: str | None = Field(default=None, min_length=2, max_length=100)
    notes: str | None = Field(default=None, max_length=500)


class ScheduleOut(BaseModel):
    schedule_id: int
    sport_id: int
    sport_name: str
    icon_key: str
    coach_id: int
    coach_name: str
    session_date: date
    start_time: time
    end_time: time
    venue: str
    notes: str | None


class RosterEntry(BaseModel):
    member_id: int
    full_name: str
    attendance_id: int | None
    status: str | None


class AttendanceMark(BaseModel):
    schedule_id: int
    member_id: int
    status: Status


class AttendanceUpdate(BaseModel):
    status: Status


class AttendanceOut(BaseModel):
    attendance_id: int
    schedule_id: int
    member_id: int
    member_name: str
    sport_name: str
    session_date: date
    status: str
    marked_at: datetime | None