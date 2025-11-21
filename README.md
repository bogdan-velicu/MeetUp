# MeetUp! - Social Meetup Application

A mobile application designed to encourage real-life social meetups between friends through gamification and location-based features.

## Project Structure

```
MeetUp/
├── mobile/                 # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/           # Core utilities, constants, theme
│   │   ├── features/       # Feature-based modules
│   │   ├── shared/         # Shared widgets, models, services
│   │   └── services/       # API clients, location, notifications
│   └── pubspec.yaml
│
├── backend/                # FastAPI backend
│   ├── app/
│   │   ├── main.py
│   │   ├── core/           # Config, security, database
│   │   ├── api/v1/         # API routes
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   ├── repositories/   # Data access layer
│   │   └── utils/           # Helpers, validators
│   ├── alembic/            # Database migrations
│   └── requirements.txt
│
├── database/               # Database scripts
│   ├── migrations/
│   └── seeds/
│
└── Docs/                   # Documentation
    ├── db_schema_simplified.md
    └── MEDS2025_Raport_complementar_de_proiectare_Echipa_9.md
```

## Technology Stack

- **Frontend**: Flutter (Android/iOS)
- **Backend**: Python FastAPI
- **Database**: MariaDB
- **Maps**: Google Maps SDK
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Authentication**: JWT, OAuth (Google/Facebook)

## Getting Started

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

5. Initialize database migrations:
```bash
alembic init alembic  # If not already initialized
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

6. Run the server:
```bash
uvicorn app.main:app --reload
```

### Mobile App Setup

1. Navigate to mobile directory:
```bash
cd mobile
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Database Schema

See `Docs/db_schema_simplified.md` for the complete database schema.

## Development Roadmap

- **EPIC 1**: Basic social interaction (map, meetings, invitations)
- **EPIC 2**: Extended features (gamification, events, locations)

## License

[To be determined]

