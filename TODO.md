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
  - [ ] Implement token refresh mechanism
  - [x] Create authentication middleware
  - [x] Add role assignment on user registration (default: "user")

- [ ] **Location Services**
  - [ ] Create `LocationService` for location management
  - [ ] Implement `GET /api/v1/friends/locations` endpoint
  - [ ] Implement `PATCH /api/v1/location/update` endpoint
  - [ ] Implement `POST /api/v1/location/history` endpoint (for location history tracking)
  - [ ] Add location visibility filtering (only close friends)
  - [ ] Create location update scheduler based on user interval settings

- [ ] **Friends Service**
  - [ ] Create `FriendsService` for friend management
  - [ ] Implement `GET /api/v1/friends` endpoint
  - [ ] Implement `POST /api/v1/friends/{id}/request` endpoint
  - [ ] Implement `PATCH /api/v1/friends/{id}/accept` endpoint
  - [ ] Implement `DELETE /api/v1/friends/{id}` endpoint

- [ ] **Database Models**
  - [ ] Verify all models are properly defined (User, UserLocation, UserLocationHistory, Role, UserRole, Friendship)
  - [ ] Add any missing relationships/foreign keys
  - [ ] Test database migrations

#### Frontend Tasks
- [x] **Authentication UI**
  - [x] Create login screen
  - [x] Create registration screen
  - [x] Implement authentication state management
  - [x] Add token storage and refresh logic
  - [x] Create protected route wrapper

- [ ] **Map View**
  - [ ] Integrate Google Maps SDK
  - [ ] Create `MapView` component
  - [ ] Display current user location
  - [ ] Display friends' locations with markers
  - [ ] Show friend names and availability status on markers
  - [ ] Implement location permission handling
  - [ ] Add location update mechanism (background/foreground)

- [ ] **Friends List**
  - [ ] Create `FriendsListView` component
  - [ ] Display list of friends
  - [ ] Show friend status (available, busy, etc.)
  - [ ] Add friend request functionality

#### Testing
- [ ] Test authentication flow (register, login, token refresh)
- [ ] Test location update API endpoints
- [ ] Test friends location retrieval with privacy filters
- [ ] Test map display with multiple friends
- [ ] Test location sharing permissions

---

### SPRINT 2: Meetings & Invitations
**Goal**: Meeting creation and invitation management.

#### Backend Tasks
- [ ] **Meetings Service**
  - [ ] Create `MeetingsService` for meeting management
  - [ ] Implement `POST /api/v1/meetings` endpoint (create meeting)
  - [ ] Implement `GET /api/v1/meetings` endpoint (list user's meetings)
  - [ ] Implement `GET /api/v1/meetings/{id}` endpoint (meeting details)
  - [ ] Implement `PATCH /api/v1/meetings/{id}` endpoint (update meeting)
  - [ ] Implement `DELETE /api/v1/meetings/{id}` endpoint (cancel meeting)
  - [ ] Add validation for meeting creation

- [ ] **Invitations Service**
  - [ ] Create `InvitationsService` for invitation management
  - [ ] Implement `GET /api/v1/invitations` endpoint (list invitations)
  - [ ] Implement `GET /api/v1/invitations/{id}` endpoint (invitation details)
  - [ ] Implement `PATCH /api/v1/invitations/{id}` endpoint (accept/decline)
  - [ ] Add automatic invitation creation when meeting is created
  - [ ] Implement notification triggers on invitation status change

- [ ] **Notifications**
  - [ ] Set up FCM integration
  - [ ] Create notification service
  - [ ] Send push notification when invitation is created
  - [ ] Send push notification when invitation is accepted/declined
  - [ ] Store notification preferences per user

#### Frontend Tasks
- [ ] **Meeting Creation**
  - [ ] Create `MeetingCreateView` component
  - [ ] Implement friend selection (multi-select)
  - [ ] Implement location picker (map or search)
  - [ ] Add date/time picker
  - [ ] Add meeting title and description fields
  - [ ] Implement form validation
  - [ ] Add submit functionality

- [ ] **Meetings List**
  - [ ] Create `MeetingListView` component
  - [ ] Display user's organized meetings
  - [ ] Show meeting status (pending, confirmed, cancelled, completed)
  - [ ] Add filter options (upcoming, past, all)
  - [ ] Implement pull-to-refresh

- [ ] **Meeting Details**
  - [ ] Create `MeetingView` component
  - [ ] Display meeting information
  - [ ] Show participant list with status
  - [ ] Add edit/delete functionality (for organizer)
  - [ ] Display meeting location on map

- [ ] **Invitations**
  - [ ] Create `InvitationsListView` component
  - [ ] Display received invitations
  - [ ] Create `InvitationView` component
  - [ ] Add accept/decline buttons
  - [ ] Show invitation details (organizer, location, time)
  - [ ] Implement quick actions (swipe to accept/decline)

#### Testing
- [ ] Test meeting creation flow
- [ ] Test invitation acceptance/decline
- [ ] Test notification delivery
- [ ] Test meeting update and cancellation
- [ ] Test participant status updates

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

- [ ] **Points Engine**
  - [ ] Create `PointsEngine` service
  - [ ] Implement points calculation logic
  - [ ] Award points on meeting confirmation
  - [ ] Implement `GET /api/v1/points/summary` endpoint (total points)
  - [ ] Implement `GET /api/v1/points/history` endpoint (transaction history)
  - [ ] Add points transaction logging
  - [ ] Update user's total_points on transaction

- [ ] **Meeting Confirmation**
  - [ ] Add meeting confirmation endpoint
  - [ ] Award points when meeting is confirmed
  - [ ] Create points transaction record
  - [ ] Send notification on points earned

#### Frontend Tasks
- [ ] **Groups UI**
  - [ ] Create `GroupsView` component (list of groups)
  - [ ] Create `GroupView` component (group details)
  - [ ] Add create group functionality
  - [ ] Implement add/remove members UI
  - [ ] Add leave group button
  - [ ] Display group members list
  - [ ] Show group admin indicators

- [ ] **Profile & Points**
  - [ ] Update `ProfileView` to display total points
  - [ ] Create points history view
  - [ ] Display points transaction list
  - [ ] Show points earned breakdown
  - [ ] Add meeting confirmation button (with points reward)

#### Testing
- [ ] Test group creation and member management
- [ ] Test points calculation and awarding
- [ ] Test points history display
- [ ] Test meeting confirmation and points reward
- [ ] Test group permissions (admin vs member)

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
- [ ] Set up unit testing framework (backend: pytest, frontend: flutter_test)
- [ ] Achieve minimum 60% code coverage
- [ ] Set up integration testing
- [ ] Set up API testing (Postman/HTTPX)
- [ ] Create test data fixtures

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

**Last Updated**: [Date will be updated as progress is made]

