# Mock User Accounts

Here are the mock user accounts that were created for testing:

## Mock Users
All mock users have the same password: **`password123`**

| Username | Email | Full Name | Password | Location | Status |
|----------|-------|-----------|----------|----------|---------|
| `alice_smith` | `alice@example.com` | Alice Smith | `password123` | Old Town, Bucharest | Available |
| `bob_jones` | `bob@example.com` | Bob Jones | `password123` | Herastrau Park, Bucharest | Busy |
| `charlie_brown` | `charlie@example.com` | Charlie Brown | `password123` | Unirii Square, Bucharest | Away |
| `diana_prince` | `diana@example.com` | Diana Prince | `password123` | Aviatorilor, Bucharest | Available |

## How to Test

1. **Login with any mock account:**
   - Email: `alice@example.com`
   - Password: `password123`

2. **Search for friends:**
   - Go to Friends tab → Add Friends (+ button)
   - Search for: `bob`, `charlie`, `diana`, etc.
   - Send friend requests

3. **View on Map:**
   - Go to Map tab
   - You should see friends as custom circular markers
   - Tap markers to see profile popups with zoom animation

## Features to Test

✅ **Friend Management:**
- Add friends by searching usernames
- Remove friends via the options menu
- View friends list with status indicators

✅ **Map Features:**
- Custom profile picture markers
- Status color rings (Green=Available, Red=Busy, Orange=Away)
- Tap markers for detailed popups
- Zoom animations when tapping markers
- "My Location" button (blue gradient marker)
- "Show All Friends" button with friend count badge

✅ **UI Polish:**
- Beautiful bottom sheets and popups
- Smooth animations and transitions
- Modern card designs with shadows
- Status indicators throughout the app

✅ **Logout:**
- Red logout button in top-left of map
- Confirmation dialog with warning

## Notes
- All mock users are located around Bucharest, Romania
- The app automatically updates your location every 15 seconds
- Friends' locations are refreshed when you navigate between tabs
- Custom markers are generated using Canvas API for perfect pixel control
