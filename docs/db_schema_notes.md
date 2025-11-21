# Database Schema Notes

## Role System

The application uses a role-based system to distinguish between different types of users:

### Roles
- **user** (default): Regular users who can use basic features (meetings, friends, points, etc.)
- **organizer**: Users who can create and manage public/private events
- **venue_owner**: Users who can register and manage locations (venues)
- **admin**: System administrators with full access

### Implementation
- Users can have multiple roles (M:N relationship via `UserRole` table)
- Roles are assigned via the `UserRole` junction table
- Role status can be "active" or "revoked"
- When checking permissions, check if user has the required role with status="active"

### Usage Examples
- To check if a user can create events: Check if they have role "organizer"
- To check if a user can manage a location: Check if they have role "venue_owner" AND they own that location
- Regular users get "user" role by default on registration

## Location History

The `UserLocationHistory` table tracks all location updates for travel visualization:

### Purpose
- Store historical location data for each user
- Enable travel path visualization in the mobile app
- Track movement patterns for analytics

### Data Captured
- **recorded_at**: Timestamp when location was recorded
- **latitude/longitude**: GPS coordinates
- **altitude_m**: Elevation (optional)
- **accuracy_m**: GPS accuracy in meters
- **speed_mps**: Movement speed (optional)
- **heading_deg**: Direction of travel (optional)
- **source**: How location was obtained (gps, wifi, network, manual)

### Usage
- When user requests travel visualization, query `UserLocationHistory` filtered by:
  - `user_id` (only their own data)
  - `recorded_at` (date range if specified)
- Data can be aggregated to show travel paths on map
- Old data can be archived/cleaned based on retention policy

### Performance Considerations
- Index on `(user_id, recorded_at)` for efficient queries
- Consider data retention policies (e.g., keep last 6 months)
- Location updates happen frequently, so table will grow quickly

## Current Location vs History

- **UserLocation**: Stores only the current/latest location (one record per user)
  - Used for real-time map display
  - Updated frequently (based on `location_update_interval`)
  - Unique constraint on `user_id`

- **UserLocationHistory**: Stores all historical location records
  - Used for travel visualization and analytics
  - New record created on each location update
  - No unique constraints (multiple records per user)

## Relationship Between Tables

```
User (1) ──< (N) UserRole (N) >── (1) Role
User (1) ──< (1) UserLocation
User (1) ──< (N) UserLocationHistory
User (1) ──< (N) Location [as owner_user_id]
User (1) ──< (N) Event [as organizer_user_id]
```

