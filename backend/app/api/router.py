"""Collects every router in one place, so main.py never needs editing again."""
from fastapi import APIRouter

from app.api import auth, sports

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(sports.router)
