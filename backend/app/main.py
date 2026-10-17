"""SCMS API entry point."""
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api import auth
from app.core.config import get_settings
from app.db.session import get_db

settings = get_settings()

app = FastAPI(title="SCMS API", version="0.2.0",
              description="Sports Club Management System: backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth.router)


@app.get("/health", tags=["system"])
def health(db: Session = Depends(get_db)):
    """Proves the API is up and MySQL is reachable."""
    try:
        users = db.execute(text("SELECT COUNT(*) FROM users")).scalar_one()
    except SQLAlchemyError:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return {"status": "ok", "database": "connected", "users": users}
