# MeetUp! - Development TODO

This document tracks the development progress for the MeetUp! application, organized by EPICs and SPRINTs.

---

## 🚀 PROJECT INITIALIZATION

### Infrastructure Setup
- [x] **Database Setup**
  - [x] Create MariaDB database
  - [x] Configure database connection in backend `.env`
  - [x] Initialize Alembic migrations
  - [x] Create initial migration from schema
  - [x] Run migration to create all tables
  - [x] Create seed data for roles (user, organizer, venue_owner, admin)

- [ ] **Backend Initialization**
  - [x] Set up Python virtual environment
  - [x] Install all dependencies from `requirements.txt`
  - [x] Configure environment variables (database credentials set)
  - [x] Set up Alembic for migrations
  - [x] Create base API structure with versioning
  - [x] Implement error handling middleware
  - [x] Set up CORS configuration
  - [x] Create logging configuration

- [x] **Mobile App Initialization**
  - [x] Set up Flutter project structure (feature-based)
  - [x] Install core dependencies (HTTP client, state management, etc.)
  - [x] Configure app theme and design system
  - [x] Set up navigation structure
  - [x] Create base API service client
  - [x] Implement authentication state management
  - [x] Configure Google Maps SDK
  - [x] Set up Firebase Cloud Messaging (FCM)

---

## 📦 EPIC 1: Basic Social Interaction
**Goal**: Implement complete basic social interaction scenario between users (map visualization, location, meeting proposals, invitation acceptance).

### SPRINT 1: Infrastructure & Map Visualization
**Goal**: Infrastructure setup and friends visualization on map.

#### Backend Tasks
- [x] **Authentication System**
  - [x] Implement user registration (email + password)
  - [x] Implement user login with JWT tokens
  - [x] Create password hashing service
  - [x] Implement token refresh mechanism
  - [x] Create authentication middleware
  - [x] Add role assignment on user registration (default: "user")

- [x] **Location Services**
  - [x] Create `LocationService` for location management
  - [x] Implement `GET /api/v1/friends/locations` endpoint
  - [x] Implement `PATCH /api/v1/location/update` endpoint
  - [x] Implement `POST /api/v1/location/history` endpoint (for location history tracking)
  - [x] Add location visibility filtering (only close friends)
  - [x] Create location update scheduler based on user interval settings

- [x] **Friends Service**
  - [x] Create `FriendsService` for friend management
  - [x] Implement `GET /api/v1/friends` endpoint
  - [x] Implement `POST /api/v1/friends/{id}/request` endpoint
  - [x] Implement `PATCH /api/v1/friends/{id}/accept` endpoint
  - [x] Implement `DELETE /api/v1/friends/{id}` endpoint

- [x] **Database Models**
  - [x] Verify all models are properly defined (User, UserLocation, UserLocationHistory, Role, UserRole, Friendship)
  - [x] Models are working correctly (relationships handled in repositories)
  - [x] Test database migrations (already run)

#### Frontend Tasks
- [x] **Authentication UI**
  - [x] Create login screen
  - [x] Create registration screen
  - [x] Implement authentication state management
  - [x] Add token storage and refresh logic
  - [x] Create protected route wrapper

- [x] **Map View**
  - [x] Integrate Google Maps SDK
  - [x] Create `MapView` component
  - [x] Display current user location
  - [x] Display friends' locations with markers
  - [x] Show friend names and availability status on markers
  - [x] Implement location permission handling
  - [x] Add location update mechanism (background/foreground)

- [x] **Navigation & UI Structure**
  - [x] Create floating bottom navigation bar with rounded edges
  - [x] Create main navigation screen with tabs (Chat, Friends, Map, Events, Profile)
  - [x] Implement MapView screen with location services
  - [x] Create placeholder screens for all tabs
  - [x] Update route generator for new navigation structure

- [x] **Friends List**
  - [x] Create `FriendsListView` component
  - [x] Display list of friends
  - [x] Show friend status (available, busy, etc.)
  - [x] Add friend request functionality

#### Testing
- [x] Test authentication flow (register, login, token refresh)
- [x] Test location update API endpoints
- [x] Test friends location retrieval with privacy filters
- [x] Test map display with multiple friends
- [x] Test location sharing permissions

---

### SPRINT 2: Meetings & Invitations
**Goal**: Meeting creation and invitation management.

#### Backend Tasks
- [x] **Meetings Service**
  - [x] Create `MeetingsService` for meeting management
  - [x] Implement `POST /api/v1/meetings` endpoint (create meeting)
  - [x] Implement `GET /api/v1/meetings` endpoint (list user's meetings)
  - [x] Implement `GET /api/v1/meetings/{id}` endpoint (meeting details)
  - [x] Implement `PATCH /api/v1/meetings/{id}` endpoint (update meeting)
  - [x] Implement `DELETE /api/v1/meetings/{id}` endpoint (cancel meeting)
  - [x] Add validation for meeting creation
  - [x] Implement `POST /api/v1/meetings/{id}/participants` endpoint (add participants to existing meeting)
  - [x] Add `participant_count` field to meeting responses

- [x] **Invitations Service**
  - [x] Create `InvitationsService` for invitation management
  - [x] Implement `GET /api/v1/invitations` endpoint (list invitations)
  - [x] Implement `GET /api/v1/invitations/{id}` endpoint (invitation details)
  - [x] Implement `PATCH /api/v1/invitations/{id}` endpoint (accept/decline)
  - [x] Add automatic invitation creation when meeting is created
  - [x] Implement notification triggers on invitation status change (placeholder - needs FCM)

- [x] **Notifications**
  - [x] Set up FCM integration (frontend initialized, backend structure exists)
  - [x] Create notification service (basic structure created)
  - [x] Add FCM token storage to User model/database
  - [x] Implement API endpoint to register/update FCM tokens
  - [x] Implement FCM push notification sending in backend
  - [x] Send push notification when invitation is created
  - [x] Send push notification when invitation is accepted/declined
  - [x] Send push notification when meeting is updated/cancelled
  - [x] Send push notification when friend request is sent/accepted
  - [x] Update frontend to send FCM tokens to backend
  - [ ] Store notification preferences per user (optional enhancement)

#### Frontend Tasks
- [x] **Meeting Creation**
  - [x] Create `MeetingCreateView` component
  - [x] Implement friend selection (multi-select)
  - [x] Implement location picker (map or search)
  - [x] Add date/time picker
  - [x] Add meeting title and description fields
  - [x] Implement form validation
  - [x] Add submit functionality
  - [x] Add ability to invite friends to existing meetings

- [x] **Meetings List**
  - [x] Create `MeetingListView` component
  - [x] Display user's organized meetings
  - [x] Show meeting status (pending, confirmed, cancelled, completed)
  - [x] Add filter options (upcoming, past, all, organized, invited)
  - [x] Implement pull-to-refresh
  - [x] Fix participant count display

- [x] **Meeting Details**
  - [x] Create `MeetingView` component
  - [x] Display meeting information
  - [x] Show participant list with status (with user names)
  - [x] Add edit/delete functionality (for organizer)
  - [x] Display meeting location on map

- [x] **Invitations**
  - [x] Create `InvitationsListView` component
  - [x] Display received invitations
  - [x] Create `InvitationView` component
  - [x] Add accept/decline buttons
  - [x] Show invitation details (organizer, location, time)
  - [ ] Implement quick actions (swipe to accept/decline) - optional enhancement

#### Testing
- [x] Test meeting creation flow
- [x] Test invitation acceptance/decline
- [x] Test notification delivery (FCM working correctly)
- [x] Test meeting update and cancellation
- [x] Test participant status updates
- [x] Test adding participants to existing meetings

---

### SPRINT 3: Groups & Points System
**Goal**: Group organization and points bonus system for meetings.

#### Backend Tasks
- [ ] **Groups Service**
  - [ ] Create `GroupsService` for group management
  - [ ] Implement `POST /api/v1/groups` endpoint (create group)
  - [ ] Implement `GET /api/v1/groups` endpoint (list user's groups)
  - [ ] Implement `GET /api/v1/groups/{id}` endpoint (group details)
  - [ ] Implement `PATCH /api/v1/groups/{id}/members` endpoint (add/remove members)
  - [ ] Implement `DELETE /api/v1/groups/{id}` endpoint (delete group)
  - [ ] Implement `POST /api/v1/groups/{id}/leave` endpoint (leave group)
  - [ ] Add group admin role management

- [x] **Points Engine**
  - [x] Create `PointsEngine` service (PointsService)
  - [x] Implement points calculation logic
  - [x] Award points on meeting confirmation
  - [x] Implement `GET /api/v1/points/summary` endpoint (total points)
  - [x] Implement `GET /api/v1/points/history` endpoint (transaction history)
  - [x] Add points transaction logging
  - [x] Update user's total_points on transaction

- [x] **Meeting Confirmation**
  - [x] Add meeting confirmation endpoint
  - [x] Award points when meeting is confirmed
  - [x] Create points transaction record
  - [ ] Send notification on points earned (optional enhancement)

#### Frontend Tasks
- [ ] **Groups UI**
  - [ ] Create `GroupsView` component (list of groups)
  - [ ] Create `GroupView` component (group details)
  - [ ] Add create group functionality
  - [ ] Implement add/remove members UI
  - [ ] Add leave group button
  - [ ] Display group members list
  - [ ] Show group admin indicators

- [x] **Profile & Points**
  - [x] Update `ProfileView` to display total points (already shows in stats)
  - [x] Create points history view
  - [x] Display points transaction list
  - [x] Show points earned breakdown
  - [x] Add meeting confirmation button (with points reward)

#### Testing
- [ ] Test group creation and member management
- [x] Test points calculation and awarding (test script created)
- [x] Test points history display
- [x] Test meeting confirmation and points reward
- [ ] Test group permissions (admin vs member)

---

### SPRINT 2.5: Shake to MeetUp Feature
**Goal**: Implement spontaneous meetup feature using shake detection and proximity matching.

#### Backend Tasks
- [ ] **Shake Sessions Service**
  - [ ] Create `ShakeSession` model and database table
  - [ ] Create `ShakeRepository` for database operations
  - [ ] Create `ShakeService` with proximity detection logic
  - [ ] Implement `POST /api/v1/shake/initiate` endpoint
  - [ ] Implement `GET /api/v1/shake/nearby-friends` endpoint
  - [ ] Implement `POST /api/v1/shake/match` endpoint
  - [ ] Add automatic meeting creation on shake match
  - [ ] Integrate points awarding on match (requires points system)
  - [ ] Add cleanup job for expired shake sessions
  - [ ] Implement proximity detection algorithm (Haversine formula)

#### Frontend Tasks
- [ ] **Shake Detection**
  - [ ] Add `sensors_plus` package for accelerometer access
  - [ ] Create `ShakeDetectionService` class
  - [ ] Implement shake detection algorithm
  - [ ] Create shake detection UI component
  - [ ] Add visual feedback (animations, haptics)
  - [ ] Integrate with backend shake endpoints
  - [ ] Handle shake session lifecycle

- [ ] **Shake Match UI**
  - [ ] Create shake match success screen
  - [ ] Show nearby friends who are shaking
  - [ ] Add countdown timer for match window
  - [ ] Create push notification for successful match
  - [ ] Show points earned notification
  - [ ] Add shake history/statistics

#### Testing
- [ ] Test shake detection accuracy
- [ ] Test proximity detection with real locations
- [ ] Test synchronization timing
- [ ] Test edge cases (multiple friends, expired sessions)
- [ ] Test points awarding (when points system is ready)
- [ ] Test automatic meeting creation

**Note**: See `docs/SHAKE_TO_MEETUP_PLAN.md` for detailed implementation plan.

---

## 🎮 EPIC 2: Extended Features & Gamification
**Goal**: Extend social features and introduce gamified elements and public/private events.

### SPRINT 4: Missions, Store & Close Friends
**Goal**: Implement missions, digital store, and close friends feature.

#### Backend Tasks
- [ ] **Missions Service**
  - [ ] Create `MissionsService` for mission management
  - [ ] Implement `GET /api/v1/missions` endpoint (list active missions)
  - [ ] Implement `GET /api/v1/missions/history` endpoint (completed missions)
  - [ ] Implement `POST /api/v1/missions/{id}/complete` endpoint
  - [ ] Add mission progress tracking
  - [ ] Award points on mission completion
  - [ ] Send notification on mission completion

- [ ] **Store Service**
  - [ ] Create `StoreService` for store management
  - [ ] Implement `GET /api/v1/store/items` endpoint (list items)
  - [ ] Implement `POST /api/v1/store/purchase` endpoint (purchase item)
  - [ ] Add points deduction on purchase
  - [ ] Validate user has enough points
  - [ ] Create purchase transaction record
  - [ ] Handle feature unlocks (if item_type is feature_unlock)

- [ ] **Close Friends**
  - [ ] Update `FriendsService` with close friend functionality
  - [ ] Implement `PATCH /api/v1/friends/{id}/close-status` endpoint
  - [ ] Update location visibility logic to check close_friend flag
  - [ ] Add close friend indicator in friend list response

#### Frontend Tasks
- [ ] **Missions UI**
  - [ ] Create `MissionsListView` component
  - [ ] Display active missions with progress
  - [ ] Create `MissionsHistoryView` component
  - [ ] Show completed missions and rewards
  - [ ] Add mission completion button
  - [ ] Display mission criteria and rewards

- [ ] **Store UI**
  - [ ] Create `StoreView` component
  - [ ] Display store items with points cost
  - [ ] Create `StorePurchaseConfirmation` component
  - [ ] Show user's available points
  - [ ] Implement purchase flow
  - [ ] Display purchase success message

- [ ] **Close Friends UI**
  - [ ] Update `FriendsListView` with close friend toggle
  - [ ] Add visual indicator for close friends
  - [ ] Implement toggle functionality

#### Testing
- [ ] Test mission completion and points reward
- [ ] Test store purchase flow
- [ ] Test close friend toggle and location visibility
- [ ] Test points deduction on purchase

---

### SPRINT 5: Privacy & Availability Settings
**Goal**: Privacy settings and availability management.

#### Backend Tasks
- [ ] **Privacy Settings**
  - [ ] Create `PrivacyService` for privacy management
  - [ ] Implement `GET /api/v1/privacy/location-visibility` endpoint
  - [ ] Implement `PATCH /api/v1/location-sharing` endpoint (enable/disable)
  - [ ] Implement `PATCH /api/v1/location-update-interval` endpoint
  - [ ] Update location sharing logic based on settings
  - [ ] Add location history tracking when sharing enabled

- [ ] **Availability Service**
  - [ ] Create `AvailabilityService` for availability management
  - [ ] Implement `PATCH /api/v1/availability-status` endpoint
  - [ ] Implement `POST /api/v1/availability-schedule` endpoint
  - [ ] Implement `GET /api/v1/availability-schedule` endpoint
  - [ ] Implement `DELETE /api/v1/availability-schedule/{id}` endpoint
  - [ ] Add availability status to user profile response

#### Frontend Tasks
- [ ] **Privacy Settings UI**
  - [ ] Create `PrivacySettingsView` component
  - [ ] Add location sharing toggle
  - [ ] Add location update interval selector (5, 15, 30 min, manual)
  - [ ] Display who can see location (close friends list)
  - [ ] Add visual indicator when location sharing is disabled
  - [ ] Show location visibility status

- [ ] **Availability UI**
  - [ ] Update `ProfileView` with availability status dropdown
  - [ ] Create `AvailabilityScheduleView` component
  - [ ] Add day-of-week and time slot selection
  - [ ] Display availability schedule (calendar/chips view)
  - [ ] Show availability status in friends list and map

#### Testing
- [ ] Test location sharing enable/disable
- [ ] Test location update interval changes
- [ ] Test availability status updates
- [ ] Test availability schedule creation
- [ ] Test location visibility filtering

---

### SPRINT 6: Events, Analytics & Locations
**Goal**: Public/private events, analytics, and location management.

#### Backend Tasks
- [ ] **Events Service**
  - [ ] Create `EventsService` for event management
  - [ ] Implement `POST /api/v1/events` endpoint (create event)
  - [ ] Implement `GET /api/v1/events/created` endpoint (organizer's events)
  - [ ] Implement `GET /api/v1/events/{id}` endpoint (event details)
  - [ ] Implement `PATCH /api/v1/events/{id}` endpoint (update event)
  - [ ] Implement `DELETE /api/v1/events/{id}` endpoint (delete event)
  - [ ] Implement `POST /api/v1/events/{id}/invite` endpoint (invite users)
  - [ ] Implement `GET /api/v1/events/{id}/participants-status` endpoint
  - [ ] Implement `PATCH /api/v1/events/{id}/bonus` endpoint (set bonus points)
  - [ ] Implement `PATCH /api/v1/events/{id}/eligibility` endpoint
  - [ ] Add eligibility validation service
  - [ ] Award bonus points on event participation
  - [ ] Add role check (only organizers can create events)

- [ ] **Analytics Service**
  - [ ] Create `AnalyticsService` for analytics
  - [ ] Implement `GET /api/v1/analytics/meetings-history` endpoint
  - [ ] Implement `GET /api/v1/analytics/top-places` endpoint
  - [ ] Implement `GET /api/v1/analytics/ai-insights` endpoint
  - [ ] Add AI/ML module for personalized insights
  - [ ] Calculate meeting statistics over time periods

- [ ] **Leaderboard Service**
  - [ ] Create `LeaderboardService` for leaderboards
  - [ ] Implement `GET /api/v1/leaderboard/friends` endpoint
  - [ ] Calculate rankings based on confirmed meetings
  - [ ] Add filter for close friends only

- [ ] **Locations Service (Venue Owners)**
  - [ ] Create `LocationsService` for location management
  - [ ] Implement `POST /api/v1/locations` endpoint (register location)
  - [ ] Implement `GET /api/v1/locations/{id}` endpoint (location details)
  - [ ] Implement `PATCH /api/v1/locations/{id}` endpoint (update location)
  - [ ] Implement `POST /api/v1/locations/{id}/campaigns` endpoint
  - [ ] Implement `POST /api/v1/locations/{id}/poi-request` endpoint
  - [ ] Implement `PATCH /api/v1/locations/{id}/poi-status` endpoint (admin approval)
  - [ ] Implement `POST /api/v1/locations/{id}/reviews` endpoint
  - [ ] Implement `GET /api/v1/locations/{id}/reviews` endpoint
  - [ ] Update location average_rating on new review
  - [ ] Add role check (venue_owner for location management)
  - [ ] Add admin role check for POI approval

#### Frontend Tasks
- [ ] **Events UI**
  - [ ] Create `EventCreateView` component
  - [ ] Add event form (title, description, location, date/time)
  - [ ] Add public/private toggle
  - [ ] Add bonus points field
  - [ ] Add eligibility criteria configuration
  - [ ] Create `EventDetailsView` component
  - [ ] Display event information
  - [ ] Show participant list and status
  - [ ] Add invite friends functionality
  - [ ] Show eligibility indicator
  - [ ] Add edit/delete functionality (for organizer)

- [ ] **Analytics UI**
  - [ ] Create `SocialInsightsView` component
  - [ ] Display meeting history charts
  - [ ] Show top places visited
  - [ ] Display AI-generated insights
  - [ ] Add date range filters

- [ ] **Leaderboard UI**
  - [ ] Create `LeaderboardView` component
  - [ ] Display friends ranking
  - [ ] Show meeting counts per friend
  - [ ] Add filter for close friends only

- [ ] **Locations UI (Venue Owners)**
  - [ ] Create `LocationCreateView` component
  - [ ] Add location registration form
  - [ ] Create `LocationProfileView` component
  - [ ] Display location information
  - [ ] Add image upload for location
  - [ ] Create `LocationDetailsView` component (for all users)
  - [ ] Display location reviews and ratings
  - [ ] Create `ReviewsSection` component
  - [ ] Add review submission form
  - [ ] Show average rating and review count
  - [ ] Display active campaigns
  - [ ] Add POI request functionality (for venue owners)

#### Testing
- [ ] Test event creation (organizer role required)
- [ ] Test event invitation and participation
- [ ] Test eligibility criteria validation
- [ ] Test bonus points on event participation
- [ ] Test analytics endpoints
- [ ] Test leaderboard calculations
- [ ] Test location registration (venue_owner role required)
- [ ] Test location reviews and ratings
- [ ] Test POI approval (admin role required)

---

## 🔧 GENERAL TASKS (Across All Sprints)

### Code Quality
- [ ] Set up code linting (backend: flake8/black, frontend: dart analyze)
- [ ] Set up code formatting (backend: black, frontend: dart format)
- [ ] Configure pre-commit hooks
- [ ] Set up code review process

### Testing
- [x] Set up unit testing framework (backend: pytest, frontend: flutter_test)
- [x] Achieve minimum 60% code coverage (currently 68%)
- [ ] Set up integration testing
- [ ] Set up API testing (Postman/HTTPX)
- [x] Create test data fixtures

### Documentation
- [ ] Document API endpoints (OpenAPI/Swagger)
- [ ] Create API usage examples
- [ ] Document database schema
- [ ] Create deployment guide
- [ ] Document environment setup

### Security
- [ ] Implement HTTPS for all API calls
- [ ] Add input validation on all endpoints
- [ ] Implement rate limiting
- [ ] Add SQL injection prevention
- [ ] Implement XSS protection
- [ ] Add CSRF protection
- [ ] Secure password storage (already using hashing)
- [ ] Implement JWT token expiration and refresh

### Performance
- [ ] Optimize database queries (add missing indexes)
- [ ] Implement API response caching where appropriate
- [ ] Optimize location update frequency
- [ ] Add pagination for list endpoints
- [ ] Optimize image uploads and storage

### Deployment
- [ ] Set up production database
- [ ] Configure production environment variables
- [ ] Set up CI/CD pipeline
- [ ] Create deployment scripts
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy

---

## 📝 NOTES

- Update this TODO as tasks are completed
- Mark tasks with `[x]` when done
- Add notes or blockers in comments if needed
- Review and update after each sprint

---

**Last Updated**: December 10, 2025

**Recent Updates**:
- ✅ FCM notifications fully implemented and tested
- ✅ Location picker modal implemented for meeting creation
- 📋 Shake to MeetUp feature planned (see `docs/SHAKE_TO_MEETUP_PLAN.md`)

