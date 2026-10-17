"""Sports routes. Everyone logged in can read; only admins can change."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.user import User
from app.schemas.sport import SportCreate, SportOut, SportUpdate
from app.services import sport_service

router = APIRouter(prefix="/sports", tags=["sports"])


@router.get("", response_model=list[SportOut])
def list_sports(db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return sport_service.list_sports(db)


@router.get("/{sport_id}", response_model=SportOut)
def get_sport(sport_id: int, db: Session = Depends(get_db),
              _user: User = Depends(get_current_user)):
    return sport_service.get_sport(db, sport_id)


@router.post("", response_model=SportOut, status_code=201)
def create_sport(data: SportCreate, db: Session = Depends(get_db),
                 _admin: User = Depends(require_roles("admin"))):
    return sport_service.create_sport(db, data)


@router.patch("/{sport_id}", response_model=SportOut)
def update_sport(sport_id: int, data: SportUpdate, db: Session = Depends(get_db),
                 _admin: User = Depends(require_roles("admin"))):
    return sport_service.update_sport(db, sport_id, data)


@router.delete("/{sport_id}", status_code=204)
def delete_sport(sport_id: int, db: Session = Depends(get_db),
                 _admin: User = Depends(require_roles("admin"))):
    sport_service.delete_sport(db, sport_id)
