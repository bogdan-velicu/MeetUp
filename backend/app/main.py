from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.middleware import exception_handler, general_exception_handler
from app.core.exceptions import MeetUpException
from app.core.logging_config import setup_logging
from app.core.firebase_admin import initialize_firebase
from app.api.v1 import auth, friends, location, users, meetings, invitations, notifications, points

logger = setup_logging()

# Initialize Firebase Admin SDK on startup
try:
    initialize_firebase()
except Exception as e:
    logger.warning(f"Firebase initialization failed: {e}. FCM notifications will not work.")

app = FastAPI(
    title="MeetUp API",
    description="Backend API for MeetUp mobile application",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
app.add_exception_handler(MeetUpException, exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(friends.router, prefix="/api/v1")
app.include_router(location.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(meetings.router, prefix="/api/v1")
app.include_router(invitations.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")
app.include_router(points.router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "MeetUp API", "version": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

