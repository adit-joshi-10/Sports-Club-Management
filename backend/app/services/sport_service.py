"""Business logic for sports (no HTTP code)."""
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import ConflictError, NotFoundError
from app.models.sport import Sport
from app.schemas.sport import SportCreate, SportUpdate


def list_sports(db: Session) -> list[Sport]:
    return list(db.scalars(select(Sport).order_by(Sport.name)))


def get_sport(db: Session, sport_id: int) -> Sport:
    sport = db.get(Sport, sport_id)
    if sport is None:
        raise NotFoundError("Sport not found")
    return sport


def create_sport(db: Session, data: SportCreate) -> Sport:
    sport = Sport(**data.model_dump())
    db.add(sport)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise ConflictError("A sport with this name already exists")
    db.refresh(sport)
    return sport


def update_sport(db: Session, sport_id: int, data: SportUpdate) -> Sport:
    sport = get_sport(db, sport_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(sport, field, value)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise ConflictError("A sport with this name already exists")
    db.refresh(sport)
    return sport


def delete_sport(db: Session, sport_id: int) -> None:
    sport = get_sport(db, sport_id)
    db.delete(sport)
    try:
        db.commit()
    except IntegrityError:
        # Foreign keys (ON DELETE RESTRICT) block deleting a sport that is in use
        db.rollback()
        raise ConflictError("This sport has registrations or schedules and cannot be deleted")
