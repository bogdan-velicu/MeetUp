# Notification Testing Guide

## 📱 When Notifications Are Sent

### ✅ Currently Implemented:

1. **Friend Requests**
   - ✅ When someone sends you a friend request
   - ✅ When someone accepts your friend request

2. **Meeting Invitations**
   - ✅ When you're invited to a meeting
   - ✅ When someone accepts your meeting invitation
   - ✅ When someone declines your meeting invitation

3. **Meeting Updates**
   - ✅ When a meeting you're part of is updated (time/location changed)
   - ✅ When a meeting you're part of is cancelled

---

## 🧪 Testing Scenarios

### Prerequisites
1. **Two devices/users** (or use emulator + physical device)
2. **Both users logged in** with FCM tokens registered
3. **Backend running** with Firebase configured
4. **Both users are friends** (for meeting invitations)

---

### Test 1: Friend Request Notification

**Setup:**
- User A and User B (not friends yet)

**Steps:**
1. User A sends friend request to User B
2. **Expected**: User B receives push notification: "New Friend Request - [User A] sent you a friend request"

**Verify:**
- ✅ Notification appears on User B's device
- ✅ Notification title: "New Friend Request"
- ✅ Notification body shows User A's name
- ✅ Tapping notification opens friend requests screen

---

### Test 2: Friend Request Accepted Notification

**Setup:**
- User A sent friend request to User B (pending)

**Steps:**
1. User B accepts the friend request
2. **Expected**: User A receives push notification: "Friend Request Accepted - [User B] accepted your friend request"

**Verify:**
- ✅ Notification appears on User A's device
- ✅ Notification title: "Friend Request Accepted"
- ✅ Notification body shows User B's name
- ✅ Tapping notification opens friends list

---

### Test 3: Meeting Invitation Notification

**Setup:**
- User A and User B are friends
- User A is logged in on Device 1
- User B is logged in on Device 2

**Steps:**
1. User A creates a meeting and invites User B
2. **Expected**: User B receives push notification: "New Meeting Invitation - [User A] invited you to '[Meeting Title]'"

**Verify:**
- ✅ Notification appears on User B's device
- ✅ Notification shows meeting title
- ✅ Notification shows organizer name
- ✅ Tapping notification opens invitations screen

---

### Test 4: Meeting Invitation Accepted Notification

**Setup:**
- User A created a meeting and invited User B
- User B has pending invitation

**Steps:**
1. User B accepts the meeting invitation
2. **Expected**: User A receives push notification: "Meeting Invitation Response - [User B] accepted your invitation to '[Meeting Title]'"

**Verify:**
- ✅ Notification appears on User A's device
- ✅ Notification shows participant name
- ✅ Notification shows meeting title
- ✅ Tapping notification opens meeting details

---

### Test 5: Meeting Invitation Declined Notification

**Setup:**
- User A created a meeting and invited User B
- User B has pending invitation

**Steps:**
1. User B declines the meeting invitation
2. **Expected**: User A receives push notification: "Meeting Invitation Response - [User B] declined your invitation to '[Meeting Title]'"

**Verify:**
- ✅ Notification appears on User A's device
- ✅ Notification shows "declined" action
- ✅ Tapping notification opens meeting details

---

### Test 6: Meeting Update Notification

**Setup:**
- User A created a meeting with User B as participant
- User B accepted the invitation

**Steps:**
1. User A updates the meeting (changes time or location)
2. **Expected**: User B receives push notification: "Meeting Update - The meeting time/location has been changed: [Meeting Title]"

**Verify:**
- ✅ Notification appears on User B's device
- ✅ Notification indicates what changed (time/location)
- ✅ Tapping notification opens meeting details

---

### Test 7: Meeting Cancelled Notification

**Setup:**
- User A created a meeting with User B as participant
- User B accepted the invitation

**Steps:**
1. User A cancels/deletes the meeting
2. **Expected**: User B receives push notification: "Meeting Update - The meeting has been cancelled: [Meeting Title]"

**Verify:**
- ✅ Notification appears on User B's device
- ✅ Notification indicates meeting was cancelled
- ✅ Tapping notification opens meeting details (if still accessible)

---

## 🔍 How to Verify Notifications Are Working

### Backend Logs
Check backend console for:
```
INFO: Sent friend request notification to user X
INFO: Sent invitation notification to user Y
```

### Database Check
```sql
-- Check if FCM tokens are stored
SELECT id, username, fcm_token FROM users WHERE fcm_token IS NOT NULL;

-- Should show tokens for logged-in users
```

### Frontend Debug
Check Flutter console for:
```
FCM Token: [token]
FCM token registered with backend
```

---

## 🐛 Troubleshooting

### No Notifications Received

1. **Check FCM Token Registration**
   ```sql
   SELECT id, username, fcm_token FROM users WHERE id = ?;
   ```
   - If `fcm_token` is NULL, token wasn't registered
   - Solution: Re-login on the device

2. **Check Backend Logs**
   - Look for "Firebase not initialized" warnings
   - Check for FCM sending errors
   - Verify Firebase credentials path is correct

3. **Check Device Permissions**
   - Android: Settings → Apps → MeetUp → Notifications (should be enabled)
   - iOS: Settings → Notifications → MeetUp (should be enabled)

4. **Check Notification Preferences**
   - Backend checks preferences before sending
   - Default is enabled, but verify in code

### Notifications Sent But Not Received

1. **Invalid FCM Token**
   - Token might be expired or invalid
   - Backend logs will show "UnregisteredError"
   - Solution: User needs to re-login to get new token

2. **Device Offline**
   - FCM requires internet connection
   - Notifications are queued but may be delayed

3. **App Killed**
   - Background notifications should still work
   - Foreground notifications require app to be running

---

## 📊 Notification Types Reference

| Type | Trigger | Recipient | Data Payload |
|------|---------|-----------|--------------|
| `friend_request` | Friend request sent | Request recipient | `{"type": "friend_request", "action": "view_friend_requests"}` |
| `friend_request_accepted` | Friend request accepted | Original sender | `{"type": "friend_request_accepted", "action": "view_friends"}` |
| `meeting_invitation` | Meeting created with participants | All participants | `{"type": "meeting_invitation", "meeting_id": "123", "action": "view_invitation"}` |
| `invitation_response` | Invitation accepted/declined | Meeting organizer | `{"type": "invitation_response", "meeting_id": "123", "response": "accepted/declined", "action": "view_meeting"}` |
| `meeting_update` | Meeting updated/cancelled | All participants | `{"type": "meeting_update", "meeting_id": "123", "update_type": "time_changed/location_changed/cancelled", "action": "view_meeting"}` |

---

## 🎯 Quick Test Checklist

- [ ] Friend request sent → Notification received
- [ ] Friend request accepted → Notification received
- [ ] Meeting invitation → Notification received
- [ ] Invitation accepted → Notification received
- [ ] Invitation declined → Notification received
- [ ] Meeting updated → Notification received
- [ ] Meeting cancelled → Notification received
- [ ] Notification tap → Correct screen opens
- [ ] Foreground notifications display
- [ ] Background notifications display

---

## 💡 Tips for Testing

1. **Use Two Real Devices**: Emulators can have FCM issues
2. **Check Both Foreground & Background**: Test with app open and closed
3. **Monitor Backend Logs**: Watch for errors or warnings
4. **Test Token Refresh**: Logout/login to get new token
5. **Test Network Conditions**: Try with poor connectivity

---

## 🚀 Next Steps After Testing

Once notifications are working:
1. Test notification preferences (when implemented)
2. Test notification grouping (multiple notifications)
3. Test notification actions (buttons in notifications)
4. Test notification history (in-app notification list)

