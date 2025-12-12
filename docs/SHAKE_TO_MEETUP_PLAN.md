# Shake to MeetUp Feature - Implementation Plan

## Overview
A gamified feature that allows two friends who are physically close to each other to create an instant meeting by both shaking their phones simultaneously. This creates a spontaneous meetup and awards points to both participants.

## Feature Requirements

### Core Functionality
1. **Proximity Detection**: Detect when two friends are within a certain distance (e.g., 50-100 meters)
2. **Shake Detection**: Detect when a user shakes their phone using accelerometer/gyroscope
3. **Synchronization**: Both users must shake within a time window (e.g., 10-15 seconds)
4. **Automatic Meeting Creation**: Create a meeting automatically when both users shake
5. **Points Award**: Award points to both participants for the spontaneous meetup

## Technical Architecture

### Backend Components

#### 1. Shake Detection Service
**Purpose**: Handle shake detection requests and manage shake sessions

**Endpoints**:
- `POST /api/v1/shake/initiate` - Start a shake session (when user shakes)
- `GET /api/v1/shake/nearby-friends` - Get list of nearby friends who are also shaking
- `POST /api/v1/shake/match` - Match two users who shook simultaneously
- `GET /api/v1/shake/active-sessions` - Get active shake sessions for current user

**Database Schema**:
```sql
CREATE TABLE shake_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    created_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    matched_user_id INT NULL,
    status ENUM('active', 'matched', 'expired') DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (matched_user_id) REFERENCES users(id),
    INDEX idx_user_expires (user_id, expires_at),
    INDEX idx_location (latitude, longitude)
);
```

#### 2. Proximity Detection Logic
**Algorithm**:
1. When user shakes, create a shake session with their current location
2. Query for nearby friends (within 100m radius) who have active shake sessions
3. Check if any nearby friend's shake session was created within the time window (e.g., 15 seconds)
4. If match found, create meeting and award points

**Distance Calculation**:
- Use Haversine formula for distance calculation
- Consider location accuracy/uncertainty
- Filter by friendship status (must be friends)

#### 3. Automatic Meeting Creation
**When to Create**:
- When two shake sessions match
- Both users are friends
- Both sessions are within time window
- Both sessions are within proximity threshold

**Meeting Details**:
- Title: "Spontaneous MeetUp with [Friend Name]"
- Description: "Created via Shake to MeetUp!"
- Location: Midpoint between two users or current location
- Scheduled At: Current time (or immediate)
- Status: "confirmed" (since both agreed by shaking)
- Participants: Both users

#### 4. Points System Integration
**Points Award**:
- Base points: 50 points per user
- Bonus points: Additional 25 points if meeting is confirmed later
- Points transaction type: "shake_meetup"

### Frontend Components

#### 1. Shake Detection Service
**Purpose**: Detect phone shake using device sensors

**Implementation**:
- Use `sensors_plus` or `shake` package for Flutter
- Monitor accelerometer data
- Detect shake pattern (threshold-based)
- Send shake event to backend

**Shake Detection Algorithm**:
```dart
- Monitor accelerometer readings
- Calculate acceleration magnitude
- Detect when magnitude exceeds threshold (e.g., 2.5g)
- Count consecutive high-magnitude readings
- Trigger shake event when pattern detected
```

#### 2. Shake UI Component
**Purpose**: Visual feedback and shake detection UI

**Features**:
- Shake button/indicator
- Visual feedback when shaking detected
- Show nearby friends who are also shaking
- Show countdown timer for match window
- Success animation when match found
- Error handling for no nearby friends

#### 3. Background Shake Detection
**Purpose**: Allow shake detection even when app is in background

**Implementation**:
- Use background location updates
- Use background sensor access (if available)
- Or use foreground service with notification

## User Flow

### Scenario 1: Successful Shake Match
1. User A and User B are friends and within 100m of each other
2. User A shakes their phone
   - App detects shake
   - Creates shake session on backend
   - Shows "Looking for nearby friends..." UI
3. User B shakes their phone (within 15 seconds)
   - App detects shake
   - Creates shake session on backend
   - Backend detects match
4. Both users receive notification:
   - "🎉 Shake Match! Meeting created with [Friend Name]"
   - Points awarded notification
5. Meeting is automatically created
6. Both users can view meeting in their meetings list

### Scenario 2: No Match
1. User A shakes their phone
2. No nearby friends shake within time window
3. After 15 seconds, show message:
   - "No nearby friends detected. Try again!"
4. Shake session expires

### Scenario 3: Multiple Nearby Friends
1. User A shakes
2. Multiple friends (B, C, D) are nearby
3. First friend to shake (e.g., B) within time window matches
4. Other friends (C, D) can still shake to match with each other

## Implementation Phases

### Phase 1: Backend Foundation
**Tasks**:
- [ ] Create `shake_sessions` table migration
- [ ] Create `ShakeSession` model
- [ ] Create `ShakeRepository` for database operations
- [ ] Create `ShakeService` with proximity detection logic
- [ ] Implement `POST /api/v1/shake/initiate` endpoint
- [ ] Implement `GET /api/v1/shake/nearby-friends` endpoint
- [ ] Implement `POST /api/v1/shake/match` endpoint
- [ ] Add automatic meeting creation on match
- [ ] Integrate points awarding on match
- [ ] Add cleanup job for expired sessions

**Estimated Time**: 2-3 days

### Phase 2: Frontend Shake Detection
**Tasks**:
- [ ] Add `sensors_plus` or `shake` package to `pubspec.yaml`
- [ ] Create `ShakeDetectionService` class
- [ ] Implement shake detection algorithm
- [ ] Create shake detection UI component
- [ ] Add visual feedback (animations, haptics)
- [ ] Integrate with backend shake endpoints
- [ ] Handle shake session lifecycle
- [ ] Add error handling and retry logic

**Estimated Time**: 2-3 days

### Phase 3: Match UI & Notifications
**Tasks**:
- [ ] Create shake match success screen
- [ ] Show nearby friends who are shaking
- [ ] Add countdown timer for match window
- [ ] Create push notification for successful match
- [ ] Add meeting details view for shake-created meetings
- [ ] Show points earned notification
- [ ] Add shake history/statistics

**Estimated Time**: 2 days

### Phase 4: Testing & Polish
**Tasks**:
- [ ] Test shake detection accuracy
- [ ] Test proximity detection with real locations
- [ ] Test synchronization timing
- [ ] Test edge cases (multiple friends, expired sessions)
- [ ] Test points awarding
- [ ] Test meeting creation
- [ ] Add analytics/tracking
- [ ] Performance optimization

**Estimated Time**: 2 days

## Technical Considerations

### Proximity Detection
- **Distance Threshold**: 50-100 meters (configurable)
- **Location Accuracy**: Consider GPS accuracy (may vary)
- **Privacy**: Only check proximity with friends
- **Performance**: Use spatial indexing for efficient queries

### Shake Detection
- **Sensitivity**: Configurable threshold (default: 2.5g)
- **False Positives**: Filter out normal movement
- **Battery**: Optimize sensor usage to minimize battery drain
- **Platform Differences**: Handle iOS vs Android differences

### Synchronization
- **Time Window**: 10-15 seconds (configurable)
- **Clock Sync**: Account for device time differences
- **Network Latency**: Consider API call delays

### Security & Privacy
- **Location Privacy**: Only share location during active shake session
- **Session Expiry**: Auto-expire sessions after timeout
- **Rate Limiting**: Prevent abuse (max shakes per hour)
- **Friend Verification**: Ensure users are actually friends

## Database Schema Details

### shake_sessions Table
```sql
CREATE TABLE shake_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy_m DECIMAL(5, 2) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    matched_user_id INT NULL,
    matched_at DATETIME NULL,
    status ENUM('active', 'matched', 'expired') DEFAULT 'active',
    meeting_id INT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (matched_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE SET NULL,
    INDEX idx_user_expires (user_id, expires_at),
    INDEX idx_location (latitude, longitude),
    INDEX idx_status (status, expires_at)
);
```

## API Endpoints

### POST /api/v1/shake/initiate
**Request**:
```json
{
  "latitude": 44.4268,
  "longitude": 26.1025,
  "accuracy_m": 10.0
}
```

**Response**:
```json
{
  "session_id": 123,
  "expires_at": "2025-12-10T15:00:15Z",
  "nearby_friends_count": 2,
  "nearby_friends": [
    {
      "user_id": 6,
      "username": "bob_jones",
      "full_name": "Bob Jones",
      "distance_m": 45.2
    }
  ]
}
```

### GET /api/v1/shake/nearby-friends
**Query Parameters**:
- `session_id` (required): Current shake session ID

**Response**:
```json
{
  "nearby_friends": [
    {
      "user_id": 6,
      "username": "bob_jones",
      "full_name": "Bob Jones",
      "distance_m": 45.2,
      "is_shaking": true,
      "shake_session_id": 124
    }
  ]
}
```

### POST /api/v1/shake/match
**Request**:
```json
{
  "session_id": 123,
  "matched_session_id": 124
}
```

**Response**:
```json
{
  "success": true,
  "meeting": {
    "id": 456,
    "title": "Spontaneous MeetUp with Bob Jones",
    "status": "confirmed"
  },
  "points_awarded": 50
}
```

## Points System Integration

### Points Transaction
- **Type**: `shake_meetup`
- **Amount**: 50 points (base) + 25 points (bonus if confirmed)
- **Description**: "Shake to MeetUp with [Friend Name]"
- **Awarded to**: Both participants

### Points Calculation
```python
base_points = 50
bonus_points = 25  # If meeting is later confirmed
total_points = base_points + (bonus_points if confirmed else 0)
```

## Future Enhancements

1. **Group Shake**: Allow 3+ friends to shake together
2. **Shake Streaks**: Bonus points for consecutive shake meetups
3. **Shake Challenges**: Weekly challenges for most shake meetups
4. **Location History**: Track favorite shake locations
5. **Shake Statistics**: Show shake meetup history and stats
6. **Custom Shake Patterns**: Allow users to set custom shake sensitivity
7. **Shake Notifications**: Notify friends when you're shaking nearby

## Dependencies

### Backend
- No new dependencies (uses existing location and meeting services)

### Frontend
- `sensors_plus: ^1.2.0` - For accelerometer/gyroscope access
- Or `shake: ^2.0.0` - Alternative shake detection package

## Testing Strategy

### Unit Tests
- Shake detection algorithm
- Proximity calculation
- Time window matching logic
- Points calculation

### Integration Tests
- End-to-end shake match flow
- Meeting creation on match
- Points awarding
- Session expiry

### Manual Testing
- Real-world proximity testing
- Shake detection accuracy
- Battery impact
- Network latency handling

## Success Metrics

- Number of shake meetups created per day
- Average time to match
- Points awarded via shake feature
- User engagement with feature
- False positive rate (accidental shakes)

---

**Estimated Total Development Time**: 8-10 days
**Priority**: High (gamification feature, increases engagement)
**Dependencies**: Points system (Sprint 3) should be implemented first

