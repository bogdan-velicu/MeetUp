# Sprint 2: Meetings & Invitations - Verification Checklist

Use this checklist to verify each component as we build it. Check off items as they're completed and tested.

## Backend Components

### Phase 1: Meeting Repository
- [ ] `MeetingRepository` class created
- [ ] `create_meeting()` method implemented
- [ ] `get_meeting_by_id()` method implemented
- [ ] `get_meetings_by_organizer()` method implemented
- [ ] `get_meetings_by_participant()` method implemented
- [ ] `update_meeting()` method implemented
- [ ] `delete_meeting()` method implemented
- [ ] `add_participant()` method implemented
- [ ] `get_participants_by_meeting()` method implemented
- [ ] `update_participant_status()` method implemented
- [ ] **Test**: Run unit tests for repository
- [ ] **Test**: Manually verify database operations work

### Phase 2: Meeting Schemas
- [ ] `MeetingCreate` schema created
- [ ] `MeetingUpdate` schema created
- [ ] `MeetingResponse` schema created
- [ ] `MeetingParticipantResponse` schema created
- [ ] **Test**: Verify schemas validate correctly

### Phase 3: Meetings Service
- [ ] `MeetingsService` class created
- [ ] `create_meeting()` - creates meeting + participants
- [ ] `get_meetings()` - lists user's meetings (organized + invited)
- [ ] `get_meeting_by_id()` - gets meeting details
- [ ] `update_meeting()` - updates meeting (organizer only)
- [ ] `delete_meeting()` - deletes meeting (organizer only)
- [ ] Validation: scheduled_at must be in future
- [ ] Validation: participants must be friends
- [ ] **Test**: Run `pytest tests/unit/test_meetings_service.py -v`
- [ ] **Test**: Run manual API test script

### Phase 4: Meetings API Endpoints
- [ ] `POST /api/v1/meetings` - Create meeting
- [ ] `GET /api/v1/meetings` - List meetings (with filters)
- [ ] `GET /api/v1/meetings/{id}` - Get meeting details
- [ ] `PATCH /api/v1/meetings/{id}` - Update meeting
- [ ] `DELETE /api/v1/meetings/{id}` - Delete meeting
- [ ] Endpoints registered in main router
- [ ] **Test**: Run `python test_meetings_manual.py` - all endpoints pass
- [ ] **Test**: Verify authentication required
- [ ] **Test**: Verify organizer-only permissions work

### Phase 5: Invitations Service
- [ ] `InvitationsService` class created
- [ ] Auto-create participants when meeting created
- [ ] `get_invitations()` - list received invitations
- [ ] `get_invitation_by_id()` - get invitation details
- [ ] `accept_invitation()` - accept invitation
- [ ] `decline_invitation()` - decline invitation
- [ ] **Test**: Run unit tests
- [ ] **Test**: Run manual API test script

### Phase 6: Invitations API Endpoints
- [ ] `GET /api/v1/invitations` - List invitations
- [ ] `GET /api/v1/invitations/{id}` - Get invitation details
- [ ] `PATCH /api/v1/invitations/{id}/accept` - Accept invitation
- [ ] `PATCH /api/v1/invitations/{id}/decline` - Decline invitation
- [ ] **Test**: Run manual API test script
- [ ] **Test**: Verify only invited user can accept/decline

### Phase 7: Notifications (Basic Structure)
- [ ] `NotificationService` class created
- [ ] Basic FCM structure (placeholder)
- [ ] `send_invitation_notification()` method
- [ ] `send_invitation_response_notification()` method
- [ ] **Test**: Verify service structure (notifications will be enhanced later)

## Frontend Components

### Phase 8: Flutter Models & Services
- [ ] `Meeting` model class created
- [ ] `MeetingParticipant` model class created
- [ ] `MeetingsService` class created
- [ ] `createMeeting()` method
- [ ] `getMeetings()` method
- [ ] `getMeetingById()` method
- [ ] `updateMeeting()` method
- [ ] `deleteMeeting()` method
- [ ] `InvitationsService` class created
- [ ] `getInvitations()` method
- [ ] `acceptInvitation()` method
- [ ] `declineInvitation()` method
- [ ] **Test**: Verify API calls work (check network logs)

### Phase 9: Meeting Creation UI
- [ ] `MeetingCreateScreen` created
- [ ] Title input field
- [ ] Description input field
- [ ] Location picker (map/search)
- [ ] Date/time picker
- [ ] Friend multi-select
- [ ] Form validation
- [ ] Submit functionality
- [ ] **Test**: Create a meeting from UI
- [ ] **Test**: Verify meeting appears in list

### Phase 10: Meetings List UI
- [ ] `MeetingsListScreen` created
- [ ] Display organized meetings
- [ ] Display invited meetings
- [ ] Filter: upcoming, past, all
- [ ] Pull-to-refresh
- [ ] Tap to open details
- [ ] **Test**: List displays correctly
- [ ] **Test**: Filters work
- [ ] **Test**: Refresh works

### Phase 11: Meeting Details UI
- [ ] `MeetingDetailsScreen` created
- [ ] Display meeting information
- [ ] Show location on map
- [ ] Display participant list with status
- [ ] Edit button (organizer only)
- [ ] Delete button (organizer only)
- [ ] Navigate to location
- [ ] **Test**: Details display correctly
- [ ] **Test**: Edit/delete permissions work

### Phase 12: Invitations UI
- [ ] `InvitationsListScreen` created
- [ ] Display received invitations
- [ ] Accept button
- [ ] Decline button
- [ ] Swipe actions (optional)
- [ ] **Test**: Accept invitation works
- [ ] **Test**: Decline invitation works
- [ ] **Test**: Status updates correctly

### Phase 13: Integration
- [ ] Add meetings to navigation
- [ ] Update route generator
- [ ] Navigation flow works
- [ ] **Test**: End-to-end flow works

## Testing Commands

### Backend Unit Tests
```bash
cd backend
source venv/bin/activate
pytest tests/unit/test_meetings_service.py -v
```

### Backend Manual API Tests
```bash
cd backend
source venv/bin/activate
python test_meetings_manual.py
```

### Frontend Manual Testing
1. Start backend server
2. Run Flutter app
3. Navigate through UI
4. Check network logs for API calls
5. Verify data displays correctly

## Notes

- Test each component immediately after implementing it
- Don't move to next component until current one is verified
- Update this checklist as you complete items
- Mark items with ✅ when done and tested

