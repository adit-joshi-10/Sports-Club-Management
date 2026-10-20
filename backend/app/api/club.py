"""Routes for registrations, training schedules and attendance."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.user import User
from app.schemas.club import (
    AttendanceMark,
    AttendanceOut,
    AttendanceUpdate,
    RegistrationCreate,
    RegistrationOut,
    RosterEntry,
    ScheduleCreate,
    ScheduleOut,
    ScheduleUpdate,
)
from app.services import club_service

registrations = APIRouter(prefix="/registrations", tags=["registrations"])
schedules = APIRouter(prefix="/schedules", tags=["schedules"])
attendance = APIRouter(prefix="/attendance", tags=["attendance"])


# ---- registrations ("/me" is declared before "/{id}" on purpose)
@registrations.get("/me", response_model=list[RegistrationOut])
def my_registrations(db: Session = Depends(get_db),
                     user: User = Depends(require_roles("member"))):
    return club_service.list_registrations(db, club_service.member_id_of(db, user))


@registrations.get("", response_model=list[RegistrationOut])
def all_registrations(db: Session = Depends(get_db),
                      _admin: User = Depends(require_roles("admin"))):
    return club_service.list_registrations(db)


@registrations.post("", response_model=RegistrationOut, status_code=201)
def register_for_sport(data: RegistrationCreate, db: Session = Depends(get_db),
                       user: User = Depends(require_roles("member"))):
    return club_service.register(db, club_service.member_id_of(db, user), data.sport_id)


@registrations.delete("/{registration_id}", status_code=204)
def cancel_registration(registration_id: int, db: Session = Depends(get_db),
                        user: User = Depends(require_roles("member", "admin"))):
    club_service.cancel_registration(db, user, registration_id)


# ---- schedules
@schedules.get("", response_model=list[ScheduleOut])
def list_schedules(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return club_service.list_schedules(db, user)


@schedules.post("", response_model=ScheduleOut, status_code=201)
def create_schedule(data: ScheduleCreate, db: Session = Depends(get_db),
                    _admin: User = Depends(require_roles("admin"))):
    return club_service.create_schedule(db, data)


@schedules.patch("/{schedule_id}", response_model=ScheduleOut)
def update_schedule(schedule_id: int, data: ScheduleUpdate, db: Session = Depends(get_db),
                    _admin: User = Depends(require_roles("admin"))):
    return club_service.update_schedule(db, schedule_id, data)


@schedules.delete("/{schedule_id}", status_code=204)
def delete_schedule(schedule_id: int, db: Session = Depends(get_db),
                    _admin: User = Depends(require_roles("admin"))):
    club_service.delete_schedule(db, schedule_id)


@schedules.get("/{schedule_id}/roster", response_model=list[RosterEntry])
def session_roster(schedule_id: int, db: Session = Depends(get_db),
                   user: User = Depends(require_roles("admin", "coach"))):
    return club_service.roster(db, user, schedule_id)


# ---- attendance
@attendance.get("/me", response_model=list[AttendanceOut])
def my_attendance(db: Session = Depends(get_db),
                  user: User = Depends(require_roles("member"))):
    return club_service.my_attendance(db, user)


@attendance.get("", response_model=list[AttendanceOut])
def list_attendance(schedule_id: int | None = Query(default=None),
                    db: Session = Depends(get_db),
                    user: User = Depends(require_roles("admin", "coach"))):
    return club_service.list_attendance(db, user, schedule_id)


@attendance.post("", response_model=AttendanceOut, status_code=201)
def mark_attendance(data: AttendanceMark, db: Session = Depends(get_db),
                    user: User = Depends(require_roles("admin", "coach"))):
    return club_service.mark_attendance(db, user, data)


@attendance.patch("/{attendance_id}", response_model=AttendanceOut)
def update_attendance(attendance_id: int, data: AttendanceUpdate,
                      db: Session = Depends(get_db),
                      user: User = Depends(require_roles("admin", "coach"))):
    return club_service.update_attendance(db, user, attendance_id, data.status)