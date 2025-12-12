# MeetUp CLI Tool

An interactive console application for testing and controlling the MeetUp app. This tool provides a comprehensive interface to manage all aspects of the application through a beautiful terminal interface.

## Features

### ✅ User Management
- Login as different users
- Switch between users
- View current user info

### ✅ Friends Management
- List all friends
- List pending friend requests (incoming)
- List sent friend requests (outgoing)
- Send friend requests
- Accept friend requests
- Decline friend requests
- Remove friends

### ✅ Meetings Management
- List meetings (all, organized, invited, upcoming, past)
- Get meeting details
- Create meetings
- Update meetings
- Delete meetings
- Add participants to existing meetings

### ✅ Invitations Management
- List pending invitations
- Get invitation details
- Accept invitations
- Decline invitations

### ✅ Location Management
- Update user location
- Get friends' locations

### ✅ User Search
- Search users by username or email
- Quick friend request from search results

## Installation

1. Install dependencies:
```bash
cd backend
pip install rich requests
# Or if using requirements.txt:
pip install -r requirements.txt
```

2. Make sure the backend server is running:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Usage

### Basic Usage

```bash
cd backend
python cli_tool.py
```

Or make it executable and run directly:
```bash
chmod +x cli_tool.py
./cli_tool.py
```

### Environment Variables

You can set the API URL via environment variable:
```bash
export MEETUP_API_URL=http://192.168.0.150:8000/api/v1
python cli_tool.py
```

Default is `http://127.0.0.1:8000/api/v1`

## Quick Start Guide

1. **Start the tool:**
   ```bash
   python cli_tool.py
   ```

2. **Login:**
   - The tool will prompt you to login if not already logged in
   - Use any mock account from `MOCK_ACCOUNTS.md`
   - Example: `alice@example.com` / `password123`

3. **Navigate the menu:**
   - Use the numbered options to navigate
   - Press Enter to use defaults
   - Type `0` to go back or exit

## Example Workflow

### Testing Friend Requests

1. Login as Alice (`alice@example.com`)
2. Go to "Friends Management" → "Send Friend Request"
3. Enter Bob's user ID (e.g., `6`)
4. Switch user (option 6) and login as Bob
5. Go to "Friends Management" → "List Pending Requests"
6. Accept the request from Alice

### Testing Meetings

1. Login as Alice
2. Go to "Meetings Management" → "Create Meeting"
3. Fill in meeting details:
   - Title: "Coffee at Starbucks"
   - Description: "Let's meet for coffee"
   - Location: "Starbucks, Old Town"
   - Scheduled At: `2025-12-10T15:00:00`
   - Participant IDs: `6,7` (Bob and Charlie)
4. View the meeting details
5. Switch to Bob and check invitations
6. Accept the invitation

### Testing Location Updates

1. Login as any user
2. Go to "Location Management" → "Update My Location"
3. Enter coordinates (e.g., Bucharest: `44.4268, 26.1025`)
4. View friends' locations

## Tips

- **Quick User Switching**: Use option 6 to quickly switch between users for testing interactions
- **Batch Operations**: The tool supports comma-separated lists for participant IDs
- **Error Handling**: All errors are displayed in red with clear messages
- **Table Views**: All list operations show formatted tables for easy reading
- **Confirmation Dialogs**: Destructive operations (delete, remove) ask for confirmation

## Architecture

The CLI tool:
- Uses `rich` library for beautiful terminal formatting
- Uses `requests` for HTTP API calls
- Maintains session state (current user, token)
- Provides interactive menus for all operations
- Handles errors gracefully with user-friendly messages

## Extending the Tool

To add new features:

1. Add a new method to `MeetUpCLI` class for the API call
2. Add a menu option in the appropriate `_*_menu()` method
3. Handle the user input and call your new method

Example:
```python
def new_feature(self):
    """New feature description."""
    response = self._make_request("GET", "/new/endpoint")
    # ... handle response

def _main_menu(self):
    # ...
    console.print("  [7] New Feature")
    # ...
    elif choice == "7":
        self.new_feature()
```

## Troubleshooting

**"Cannot connect to server"**
- Make sure the backend is running
- Check the API URL in the error message
- Verify network connectivity

**"Login failed"**
- Check email/password
- Verify user exists in database
- Check backend logs for errors

**"Invalid option"**
- Make sure you're entering a valid number
- Check the menu for available options

## Maintenance

**Important:** This CLI tool should be kept in sync with the main application. When new features are added to the API, corresponding functionality should be added to this CLI tool.

### When to Update the CLI Tool

- ✅ New API endpoints added
- ✅ New request/response formats
- ✅ New user roles or permissions
- ✅ New notification types
- ✅ New data models or fields

### How to Update

1. Add new methods to `MeetUpCLI` class for new API calls
2. Add menu options in the appropriate `_*_menu()` method
3. Update this README with new features
4. Test the new functionality

## Future Enhancements

Potential additions:
- [ ] Command-line arguments for non-interactive mode
- [ ] Script recording/playback
- [ ] Batch operations from files
- [ ] Export results to JSON/CSV
- [ ] Real-time notifications display
- [ ] Performance testing mode
- [ ] Database direct access mode

