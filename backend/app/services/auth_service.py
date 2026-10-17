"""Business logic for authentication (no HTTP code here)."""
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import DUMMY_HASH, verify_password
from app.models.user import Coach, Member, User
from app.schemas.auth import UserOut


def authenticate(db: Session, email: str, password: str) -> User | None:
    """Return the user if credentials are valid and the account is active."""
    user = db.scalar(select(User).where(User.email == email.strip().lower()))
    password_ok = verify_password(password, user.password_hash if user else DUMMY_HASH)
    if user is None or not password_ok or not user.is_active:
        return None
    return user


def build_user_out(db: Session, user: User) -> UserOut:
    if user.role == "member":
        name = db.scalar(select(Member.full_name).where(Member.user_id == user.user_id))
    elif user.role == "coach":
        name = db.scalar(select(Coach.full_name).where(Coach.user_id == user.user_id))
    else:
        name = "Club Admin"
    return UserOut(user_id=user.user_id, email=user.email, role=user.role, full_name=name)
