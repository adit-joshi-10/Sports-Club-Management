
"""SCMS API entry point."""

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.router import api_router
from app.core.config import get_settings
from app.core.errors import AppError
from app.db.session import get_db

settings = get_settings()

app = FastAPI(
    title="SCMS API",
    version="0.3.0",
    description="Sports Club Management System: backend API",
)

# Allow the Flutter web frontend to communicate with FastAPI.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:5001",
        "http://127.0.0.1:5001",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppError)
async def app_error_handler(_request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
    )


@app.exception_handler(Exception)
async def unhandled_error_handler(
    _request: Request,
    _exc: Exception,
):
    # Never leak stack traces to clients.
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


app.include_router(api_router)


@app.get("/health", tags=["system"])
def health(db: Session = Depends(get_db)):
    """Proves the API is up and MySQL is reachable."""
    try:
        users = db.execute(
            text("SELECT COUNT(*) FROM users")
        ).scalar_one()
    except SQLAlchemyError:
        raise HTTPException(
            status_code=503,
            detail="Database unavailable",
        )

    return {
        "status": "ok",
        "database": "connected",
        "users": users,
    }
