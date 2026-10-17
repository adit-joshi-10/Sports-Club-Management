"""Business logic for members (no HTTP code)."""
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import AppError, ConflictError, NotFoundError
from app.core.security import hash_password
from app.models.user import Member, User
from app.schemas.member import MemberCreate, MemberOut, MemberUpdate


def _out(member: Member, email: str) -> MemberOut:
    return MemberOut(
        member_id=member.member_id,
        user_id=member.user_id,
        email=email,
        full_name=member.full_name,
        phone=member.phone,
        date_of_birth=member.date_of_birth,
        joined_on=member.joined_on,
    )


def _base_query():
    return select(Member, User.email).join(User, User.user_id == Member.user_id)


def list_members(db: Session, search: str | None = None) -> list[MemberOut]:
    stmt = _base_query().order_by(Member.full_name)
    if search and search.strip():
        like = f"%{search.strip()}%"
        stmt = stmt.where(or_(Member.full_name.ilike(like), User.email.ilike(like)))
    return [_out(m, e) for m, e in db.execute(stmt)]


def get_member(db: Session, member_id: int) -> MemberOut:
    row = db.execute(_base_query().where(Member.member_id == member_id)).first()
    if row is None:
        raise NotFoundError("Member not found")
    return _out(*row)


def get_member_for_user(db: Session, user_id: int) -> MemberOut:
    row = db.execute(_base_query().where(Member.user_id == user_id)).first()
    if row is None:
        raise NotFoundError("Member profile not found")
    return _out(*row)


def create_member(db: Session, data: MemberCreate) -> MemberOut:
    try:
        password_hash = hash_password(data.password)
    except ValueError as exc:
        raise AppError(str(exc))

    user = User(email=data.email.strip().lower(), password_hash=password_hash, role="member")
    db.add(user)
    try:
        db.flush()  # assigns user.user_id without committing yet
        db.add(Member(user_id=user.user_id, full_name=data.full_name,
                      phone=data.phone, date_of_birth=data.date_of_birth))
        db.commit()  # users row + members row saved together, or neither
    except IntegrityError:
        db.rollback()
        raise ConflictError("A user with this email already exists")
    return get_member_for_user(db, user.user_id)


def update_member(db: Session, member_id: int, data: MemberUpdate) -> MemberOut:
    member = db.get(Member, member_id)
    if member is None:
        raise NotFoundError("Member not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(member, field, value)
    db.commit()
    return get_member(db, member_id)


def delete_member(db: Session, member_id: int) -> None:
    member = db.get(Member, member_id)
    if member is None:
        raise NotFoundError("Member not found")
    user = db.get(User, member.user_id)
    db.delete(user)  # ON DELETE CASCADE removes the member row and their registrations/attendance
    db.commit()