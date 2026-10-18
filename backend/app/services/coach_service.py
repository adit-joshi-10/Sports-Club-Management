
"""Business logic for coaches (no HTTP code)."""
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import AppError, ConflictError, NotFoundError
from app.core.security import hash_password
from app.models.user import Coach, User
from app.schemas.coach import CoachCreate, CoachOut, CoachUpdate


def _out(coach: Coach, email: str) -> CoachOut:
    return CoachOut(
        coach_id=coach.coach_id,
        user_id=coach.user_id,
        email=email,
        full_name=coach.full_name,
        phone=coach.phone,
        specialization=coach.specialization,
    )


def _base_query():
    return select(Coach, User.email).join(
        User, User.user_id == Coach.user_id
    )


def list_coaches(db: Session, search: str | None = None) -> list[CoachOut]:
    stmt = _base_query().order_by(Coach.full_name)

    if search and search.strip():
        like = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Coach.full_name.ilike(like),
                Coach.specialization.ilike(like),
                User.email.ilike(like),
            )
        )

    return [_out(coach, email) for coach, email in db.execute(stmt)]


def get_coach(db: Session, coach_id: int) -> CoachOut:
    row = db.execute(
        _base_query().where(Coach.coach_id == coach_id)
    ).first()

    if row is None:
        raise NotFoundError("Coach not found")

    return _out(*row)


def create_coach(db: Session, data: CoachCreate) -> CoachOut:
    try:
        password_hash = hash_password(data.password)
    except ValueError as exc:
        raise AppError(str(exc)) from exc

    user = User(
        email=data.email.strip().lower(),
        password_hash=password_hash,
        role="coach",
    )
    db.add(user)

    try:
        db.flush()

        coach = Coach(
            user_id=user.user_id,
            full_name=data.full_name,
            phone=data.phone,
            specialization=data.specialization,
        )
        db.add(coach)
        db.commit()
        coach_id = coach.coach_id

    except IntegrityError as exc:
        db.rollback()
        raise ConflictError(
            "A user with this email already exists"
        ) from exc

    return get_coach(db, coach_id)


def update_coach(
    db: Session, coach_id: int, data: CoachUpdate
) -> CoachOut:
    coach = db.get(Coach, coach_id)

    if coach is None:
        raise NotFoundError("Coach not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(coach, field, value)

    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise ConflictError("Unable to update coach") from exc

    return get_coach(db, coach_id)


def delete_coach(db: Session, coach_id: int) -> None:
    coach = db.get(Coach, coach_id)

    if coach is None:
        raise NotFoundError("Coach not found")

    user = db.get(User, coach.user_id)

    if user is None:
        raise NotFoundError("Coach account not found")

    db.delete(user)

    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise ConflictError(
            "Coach cannot be deleted while related records depend on the account"
        ) from exc
