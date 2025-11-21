from fastapi import Request, status
from fastapi.responses import JSONResponse
from app.core.exceptions import MeetUpException
from app.core.logging_config import setup_logging

logger = setup_logging()

async def exception_handler(request: Request, exc: MeetUpException):
    """Global exception handler."""
    logger.error(f"Exception: {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

async def general_exception_handler(request: Request, exc: Exception):
    """Handle unexpected exceptions."""
    logger.exception(f"Unexpected error: {str(exc)} - Path: {request.url.path}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )

