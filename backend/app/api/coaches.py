
"""Admin-only coach management routes."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import require_roles
from app.db.session import get_db
from app.models.user import User
from app.schemas.coach import CoachCreate, CoachOut, CoachUpdate
from app.services import coach_service

router = APIRouter(prefix="/coaches", tags=["coaches"])


@router.get("", response_model=list[CoachOut])
def list_coaches(
    search: str | None = Query(default=None, max_length=60),
    db: Session = Depends(get_db),
    _admin: User = Depends(require_roles("admin")),
):
    return coach_service.list_coaches(db, search)


@router.get("/{coach_id}", response_model=CoachOut)
def get_coach(
    coach_id: int,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_roles("admin")),
):
    return coach_service.get_coach(db, coach_id)


@router.post("", response_model=CoachOut, status_code=201)
def create_coach(
    data: CoachCreate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_roles("admin")),
):
    return coach_service.create_coach(db, data)


@router.patch("/{coach_id}", response_model=CoachOut)
def update_coach(
    coach_id: int,
    data: CoachUpdate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_roles("admin")),
):
    return coach_service.update_coach(db, coach_id, data)


@router.delete("/{coach_id}", status_code=204)
def delete_coach(
    coach_id: int,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_roles("admin")),
):
    coach_service.delete_coach(db, coach_id)
