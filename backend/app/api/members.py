"""Member routes. Admin manages everyone; a member can see only their own record."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import require_roles
from app.db.session import get_db
from app.models.user import User
from app.schemas.member import MemberCreate, MemberOut, MemberUpdate
from app.services import member_service

router = APIRouter(prefix="/members", tags=["members"])


@router.get("", response_model=list[MemberOut])
def list_members(search: str | None = Query(default=None, max_length=60),
                 db: Session = Depends(get_db),
                 _admin: User = Depends(require_roles("admin"))):
    return member_service.list_members(db, search)


# "/me" must be declared BEFORE "/{member_id}", or "me" would be read as an id
@router.get("/me", response_model=MemberOut)
def my_profile(db: Session = Depends(get_db),
               user: User = Depends(require_roles("member"))):
    return member_service.get_member_for_user(db, user.user_id)


@router.get("/{member_id}", response_model=MemberOut)
def get_member(member_id: int, db: Session = Depends(get_db),
               user: User = Depends(require_roles("admin", "member"))):
    if user.role == "member":
        own = member_service.get_member_for_user(db, user.user_id)
        if own.member_id != member_id:
            raise HTTPException(status_code=403, detail="You can only view your own record")
        return own
    return member_service.get_member(db, member_id)


@router.post("", response_model=MemberOut, status_code=201)
def create_member(data: MemberCreate, db: Session = Depends(get_db),
                  _admin: User = Depends(require_roles("admin"))):
    return member_service.create_member(db, data)


@router.patch("/{member_id}", response_model=MemberOut)
def update_member(member_id: int, data: MemberUpdate, db: Session = Depends(get_db),
                  _admin: User = Depends(require_roles("admin"))):
    return member_service.update_member(db, member_id, data)


@router.delete("/{member_id}", status_code=204)
def delete_member(member_id: int, db: Session = Depends(get_db),
                  _admin: User = Depends(require_roles("admin"))):
    member_service.delete_member(db, member_id)