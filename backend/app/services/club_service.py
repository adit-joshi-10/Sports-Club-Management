"""Business logic for registrations, schedules and attendance (no HTTP code)."""
from sqlalchemy import and_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import AppError, ConflictError, NotFoundError
from app.models.club import Attendance, SportRegistration, TrainingSchedule
from app.models.sport import Sport
from app.models.user import Coach, Member, User
from app.schemas.club import (
    AttendanceMark,
    AttendanceOut,
    RegistrationOut,
    RosterEntry,
    ScheduleCreate,
    ScheduleOut,
    ScheduleUpdate,
)


class ForbiddenError(AppError):
    status_code = 403


# ---------------------------------------------------------------- identity helpers
def member_id_of(db: Session, user: User) -> int:
    member_id = db.scalar(select(Member.member_id).where(Member.user_id == user.user_id))
    if member_id is None:
        raise NotFoundError("Member profile not found")
    return member_id


def coach_id_of(db: Session, user: User) -> int:
    coach_id = db.scalar(select(Coach.coach_id).where(Coach.user_id == user.user_id))
    if coach_id is None:
        raise NotFoundError("Coach profile not found")
    return coach_id


def _assert_manages(db: Session, user: User, schedule: TrainingSchedule) -> None:
    """Admins manage everything; a coach only manages their own sessions."""
    if user.role == "admin":
        return
    if user.role == "coach" and coach_id_of(db, user) == schedule.coach_id:
        return
    raise ForbiddenError("You can only manage your own sessions")


# ---------------------------------------------------------------- registrations
def _reg_query():
    return (
        select(SportRegistration, Member.full_name, Sport.name)
        .select_from(SportRegistration)
        .join(Member, Member.member_id == SportRegistration.member_id)
        .join(Sport, Sport.sport_id == SportRegistration.sport_id)
    )


def _reg_out(reg: SportRegistration, member_name: str, sport_name: str) -> RegistrationOut:
    return RegistrationOut(
        registration_id=reg.registration_id,
        member_id=reg.member_id,
        member_name=member_name,
        sport_id=reg.sport_id,
        sport_name=sport_name,
        registered_at=reg.registered_at,
    )


def list_registrations(db: Session, member_id: int | None = None) -> list[RegistrationOut]:
    stmt = _reg_query().order_by(SportRegistration.registered_at.desc())
    if member_id is not None:
        stmt = stmt.where(SportRegistration.member_id == member_id)
    return [_reg_out(*row) for row in db.execute(stmt)]


def register(db: Session, member_id: int, sport_id: int) -> RegistrationOut:
    if db.get(Sport, sport_id) is None:
        raise NotFoundError("Sport not found")
    reg = SportRegistration(member_id=member_id, sport_id=sport_id)
    db.add(reg)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()  # UNIQUE (member_id, sport_id) rejected the duplicate
        raise ConflictError("You are already registered for this sport")
    row = db.execute(_reg_query().where(SportRegistration.registration_id == reg.registration_id)).first()
    return _reg_out(*row)


def cancel_registration(db: Session, user: User, registration_id: int) -> None:
    reg = db.get(SportRegistration, registration_id)
    if reg is None:
        raise NotFoundError("Registration not found")
    if user.role == "member" and reg.member_id != member_id_of(db, user):
        raise ForbiddenError("You can only cancel your own registrations")
    db.delete(reg)
    db.commit()


# ---------------------------------------------------------------- schedules
def _sched_query():
    return (
        select(TrainingSchedule, Sport.name, Sport.icon_key, Coach.full_name)
        .select_from(TrainingSchedule)
        .join(Sport, Sport.sport_id == TrainingSchedule.sport_id)
        .join(Coach, Coach.coach_id == TrainingSchedule.coach_id)
    )


def _sched_out(s: TrainingSchedule, sport_name: str, icon_key: str, coach_name: str) -> ScheduleOut:
    return ScheduleOut(
        schedule_id=s.schedule_id,
        sport_id=s.sport_id,
        sport_name=sport_name,
        icon_key=icon_key,
        coach_id=s.coach_id,
        coach_name=coach_name,
        session_date=s.session_date,
        start_time=s.start_time,
        end_time=s.end_time,
        venue=s.venue,
        notes=s.notes,
    )


def get_schedule(db: Session, schedule_id: int) -> ScheduleOut:
    row = db.execute(_sched_query().where(TrainingSchedule.schedule_id == schedule_id)).first()
    if row is None:
        raise NotFoundError("Session not found")
    return _sched_out(*row)


def list_schedules(db: Session, user: User) -> list[ScheduleOut]:
    """Admin: all. Coach: own sessions. Member: sessions of sports they joined."""
    stmt = _sched_query().order_by(TrainingSchedule.session_date, TrainingSchedule.start_time)
    if user.role == "coach":
        stmt = stmt.where(TrainingSchedule.coach_id == coach_id_of(db, user))
    elif user.role == "member":
        joined = select(SportRegistration.sport_id).where(
            SportRegistration.member_id == member_id_of(db, user)
        )
        stmt = stmt.where(TrainingSchedule.sport_id.in_(joined))
    return [_sched_out(*row) for row in db.execute(stmt)]


def _check_refs(db: Session, sport_id: int, coach_id: int) -> None:
    if db.get(Sport, sport_id) is None:
        raise NotFoundError("Sport not found")
    if db.get(Coach, coach_id) is None:
        raise NotFoundError("Coach not found")


def create_schedule(db: Session, data: ScheduleCreate) -> ScheduleOut:
    _check_refs(db, data.sport_id, data.coach_id)
    schedule = TrainingSchedule(**data.model_dump())
    db.add(schedule)
    db.commit()
    return get_schedule(db, schedule.schedule_id)


def update_schedule(db: Session, schedule_id: int, data: ScheduleUpdate) -> ScheduleOut:
    schedule = db.get(TrainingSchedule, schedule_id)
    if schedule is None:
        raise NotFoundError("Session not found")
    changes = {
        k: v for k, v in data.model_dump(exclude_unset=True).items()
        if v is not None or k == "notes"
    }
    start = changes.get("start_time", schedule.start_time)
    end = changes.get("end_time", schedule.end_time)
    if end <= start:
        raise AppError("End time must be after start time")
    _check_refs(db, changes.get("sport_id", schedule.sport_id),
                changes.get("coach_id", schedule.coach_id))
    for field, value in changes.items():
        setattr(schedule, field, value)
    db.commit()
    return get_schedule(db, schedule_id)


def delete_schedule(db: Session, schedule_id: int) -> None:
    schedule = db.get(TrainingSchedule, schedule_id)
    if schedule is None:
        raise NotFoundError("Session not found")
    db.delete(schedule)  # attendance rows go too (ON DELETE CASCADE)
    db.commit()


def roster(db: Session, user: User, schedule_id: int) -> list[RosterEntry]:
    """Members registered for the session's sport, with any attendance already marked."""
    schedule = db.get(TrainingSchedule, schedule_id)
    if schedule is None:
        raise NotFoundError("Session not found")
    _assert_manages(db, user, schedule)
    stmt = (
        select(Member.member_id, Member.full_name, Attendance.attendance_id, Attendance.status)
        .select_from(Member)
        .join(SportRegistration, SportRegistration.member_id == Member.member_id)
        .outerjoin(
            Attendance,
            and_(Attendance.member_id == Member.member_id,
                 Attendance.schedule_id == schedule_id),
        )
        .where(SportRegistration.sport_id == schedule.sport_id)
        .order_by(Member.full_name)
    )
    return [
        RosterEntry(member_id=r[0], full_name=r[1], attendance_id=r[2], status=r[3])
        for r in db.execute(stmt)
    ]


# ---------------------------------------------------------------- attendance
def _att_query():
    return (
        select(Attendance, Member.full_name, Sport.name, TrainingSchedule.session_date)
        .select_from(Attendance)
        .join(Member, Member.member_id == Attendance.member_id)
        .join(TrainingSchedule, TrainingSchedule.schedule_id == Attendance.schedule_id)
        .join(Sport, Sport.sport_id == TrainingSchedule.sport_id)
    )


def _att_out(a: Attendance, member_name: str, sport_name: str, session_date) -> AttendanceOut:
    return AttendanceOut(
        attendance_id=a.attendance_id,
        schedule_id=a.schedule_id,
        member_id=a.member_id,
        member_name=member_name,
        sport_name=sport_name,
        session_date=session_date,
        status=a.status,
        marked_at=a.marked_at,
    )


def _get_attendance_out(db: Session, attendance_id: int) -> AttendanceOut:
    row = db.execute(_att_query().where(Attendance.attendance_id == attendance_id)).first()
    if row is None:
        raise NotFoundError("Attendance record not found")
    return _att_out(*row)


def my_attendance(db: Session, user: User) -> list[AttendanceOut]:
    stmt = (
        _att_query()
        .where(Attendance.member_id == member_id_of(db, user))
        .order_by(TrainingSchedule.session_date.desc())
    )
    return [_att_out(*row) for row in db.execute(stmt)]


def list_attendance(db: Session, user: User, schedule_id: int | None = None) -> list[AttendanceOut]:
    """Admin: everything. Coach: only their own sessions."""
    stmt = _att_query().order_by(TrainingSchedule.session_date.desc(), Member.full_name)
    if user.role == "coach":
        stmt = stmt.where(TrainingSchedule.coach_id == coach_id_of(db, user))
    if schedule_id is not None:
        stmt = stmt.where(Attendance.schedule_id == schedule_id)
    return [_att_out(*row) for row in db.execute(stmt)]


def mark_attendance(db: Session, user: User, data: AttendanceMark) -> AttendanceOut:
    schedule = db.get(TrainingSchedule, data.schedule_id)
    if schedule is None:
        raise NotFoundError("Session not found")
    _assert_manages(db, user, schedule)
    if db.get(Member, data.member_id) is None:
        raise NotFoundError("Member not found")
    registered = db.scalar(
        select(SportRegistration.registration_id).where(
            SportRegistration.member_id == data.member_id,
            SportRegistration.sport_id == schedule.sport_id,
        )
    )
    if registered is None:
        raise AppError("This player is not registered for the session's sport")
    record = Attendance(
        schedule_id=data.schedule_id,
        member_id=data.member_id,
        status=data.status,
        marked_by_user_id=user.user_id,
    )
    db.add(record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()  # UNIQUE (schedule_id, member_id) rejected the duplicate
        raise ConflictError("Attendance is already recorded for this player")
    return _get_attendance_out(db, record.attendance_id)


def update_attendance(db: Session, user: User, attendance_id: int, status: str) -> AttendanceOut:
    record = db.get(Attendance, attendance_id)
    if record is None:
        raise NotFoundError("Attendance record not found")
    schedule = db.get(TrainingSchedule, record.schedule_id)
    _assert_manages(db, user, schedule)
    record.status = status
    record.marked_by_user_id = user.user_id
    db.commit()
    return _get_attendance_out(db, attendance_id)