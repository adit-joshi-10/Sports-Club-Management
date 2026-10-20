"""Collects every router in one place."""
from fastapi import APIRouter

from app.api import auth, club, coaches, members, sports

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(sports.router)
api_router.include_router(members.router)
api_router.include_router(coaches.router)
api_router.include_router(club.registrations)
api_router.include_router(club.schedules)
api_router.include_router(club.attendance)