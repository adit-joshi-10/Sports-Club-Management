"""ORM models for registrations, training schedules and attendance."""
from datetime import date, datetime, time

from sqlalchemy import Date, DateTime, String, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class SportRegistration(Base):
    __tablename__ = "sport_registrations"

    registration_id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column()
    sport_id: Mapped[int] = mapped_column()
    registered_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now)


class TrainingSchedule(Base):
    __tablename__ = "training_schedules"

    schedule_id: Mapped[int] = mapped_column(primary_key=True)
    sport_id: Mapped[int] = mapped_column()
    coach_id: Mapped[int] = mapped_column()
    session_date: Mapped[date] = mapped_column(Date)
    start_time: Mapped[time] = mapped_column(Time)
    end_time: Mapped[time] = mapped_column(Time)
    venue: Mapped[str] = mapped_column(String(100))
    notes: Mapped[str | None] = mapped_column(String(500))


class Attendance(Base):
    __tablename__ = "attendance"

    attendance_id: Mapped[int] = mapped_column(primary_key=True)
    schedule_id: Mapped[int] = mapped_column()
    member_id: Mapped[int] = mapped_column()
    status: Mapped[str] = mapped_column(String(10))
    marked_by_user_id: Mapped[int | None] = mapped_column()
    marked_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.now)