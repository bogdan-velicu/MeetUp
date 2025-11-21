"""
Seed script to populate initial roles in the database.
Run this after the initial migration.
"""
from sqlalchemy import create_engine, text
from app.core.config import settings

def seed_roles():
    """Insert default roles into the database."""
    engine = create_engine(settings.DATABASE_URL)
    
    roles = [
        {"name": "user", "description": "Regular user with basic features"},
        {"name": "organizer", "description": "User who can create and manage events"},
        {"name": "venue_owner", "description": "User who can register and manage locations"},
        {"name": "admin", "description": "System administrator with full access"},
    ]
    
    with engine.connect() as conn:
        for role in roles:
            # Check if role already exists
            result = conn.execute(
                text("SELECT id FROM roles WHERE name = :name"),
                {"name": role["name"]}
            )
            if result.fetchone():
                print(f"Role '{role['name']}' already exists, skipping...")
                continue
            
            # Insert role
            conn.execute(
                text("""
                    INSERT INTO roles (name, description, created_at, updated_at)
                    VALUES (:name, :description, NOW(), NOW())
                """),
                role
            )
            conn.commit()
            print(f"✓ Inserted role: {role['name']}")
    
    print("\n✅ Roles seeding completed!")

if __name__ == "__main__":
    seed_roles()

