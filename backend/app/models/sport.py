"""ORM model for the sports table."""
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Sport(Base):
    __tablename__ = "sports"

    sport_id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True)
    description: Mapped[str | None] = mapped_column(String(500))
    icon_key: Mapped[str] = mapped_column(String(30), default="generic")
