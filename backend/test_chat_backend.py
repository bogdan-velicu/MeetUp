#!/usr/bin/env python3
"""Comprehensive test script for chat backend functionality."""
import sys
import requests
import json
from typing import Dict, Optional
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:9000/api/v1"
# You'll need to set these after logging in
USER1_TOKEN: Optional[str] = None
USER2_TOKEN: Optional[str] = None
USER1_ID: Optional[int] = None
USER2_ID: Optional[int] = None

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

def print_success(message: str):
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")

def print_error(message: str):
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")

def print_info(message: str):
    print(f"{Colors.BLUE}ℹ {message}{Colors.RESET}")

def print_warning(message: str):
    print(f"{Colors.YELLOW}⚠ {message}{Colors.RESET}")

def make_request(method: str, endpoint: str, token: Optional[str] = None, data: Optional[Dict] = None) -> requests.Response:
    """Make an HTTP request with authentication."""
    url = f"{BASE_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    if method == "GET":
        return requests.get(url, headers=headers)
    elif method == "POST":
        return requests.post(url, headers=headers, json=data)
    elif method == "PATCH":
        return requests.patch(url, headers=headers, json=data)
    else:
        raise ValueError(f"Unsupported method: {method}")

def test_login(username: str, password: str) -> Optional[Dict]:
    """Test user login and return token and user info."""
    print_info(f"Logging in as {username}...")
    response = make_request("POST", "/auth/login", data={
        "identifier": username,
        "password": password
    })
    
    if response.status_code == 200:
        data = response.json()
        token = data["token"]["access_token"]
        user_id = data["user"]["id"]
        print_success(f"Logged in as {username} (ID: {user_id})")
        return {"token": token, "user_id": user_id}
    else:
        print_error(f"Login failed: {response.status_code} - {response.text}")
        return None

def test_get_conversations(token: str) -> bool:
    """Test getting all conversations."""
    print_info("Testing GET /chat/conversations...")
    response = make_request("GET", "/chat/conversations", token=token)
    
    if response.status_code == 200:
        data = response.json()
        conversations = data.get("conversations", [])
        print_success(f"Retrieved {len(conversations)} conversations")
        return True
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return False

def test_get_or_create_conversation(token: str, friend_id: int) -> Optional[int]:
    """Test getting or creating a conversation with a friend."""
    print_info(f"Testing GET /chat/conversations/{friend_id}...")
    response = make_request("GET", f"/chat/conversations/{friend_id}", token=token)
    
    if response.status_code == 200:
        data = response.json()
        conversation_id = data.get("id")
        print_success(f"Conversation ID: {conversation_id}")
        return conversation_id
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return None

def test_send_message(token: str, friend_id: int, content: str) -> Optional[Dict]:
    """Test sending a message."""
    print_info(f"Testing POST /chat/messages...")
    response = make_request("POST", "/chat/messages", token=token, data={
        "friend_id": friend_id,
        "content": content,
        "message_type": "text"
    })
    
    if response.status_code == 201:
        data = response.json()
        message_id = data.get("id")
        print_success(f"Message sent (ID: {message_id})")
        return data
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return None

def test_get_messages(token: str, conversation_id: int) -> bool:
    """Test getting message history."""
    print_info(f"Testing GET /chat/conversations/{conversation_id}/messages...")
    response = make_request("GET", f"/chat/conversations/{conversation_id}/messages?limit=50&offset=0", token=token)
    
    if response.status_code == 200:
        data = response.json()
        messages = data.get("messages", [])
        print_success(f"Retrieved {len(messages)} messages")
        if messages:
            print_info(f"Latest message: {messages[-1].get('content', '')[:50]}...")
        return True
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return False

def test_mark_as_read(token: str, conversation_id: int) -> bool:
    """Test marking conversation as read."""
    print_info(f"Testing PATCH /chat/conversations/{conversation_id}/read...")
    response = make_request("PATCH", f"/chat/conversations/{conversation_id}/read", token=token)
    
    if response.status_code == 200:
        data = response.json()
        updated_count = data.get("updated_count", 0)
        print_success(f"Marked {updated_count} messages as read")
        return True
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return False

def test_unread_count(token: str) -> bool:
    """Test getting unread count."""
    print_info("Testing GET /chat/unread-count...")
    response = make_request("GET", "/chat/unread-count", token=token)
    
    if response.status_code == 200:
        data = response.json()
        unread_count = data.get("unread_count", 0)
        print_success(f"Unread messages: {unread_count}")
        return True
    else:
        print_error(f"Failed: {response.status_code} - {response.text}")
        return False

def test_friendship_validation(token: str, non_friend_id: int) -> bool:
    """Test that chat is blocked with non-friends."""
    print_info(f"Testing friendship validation (should fail with non-friend ID: {non_friend_id})...")
    response = make_request("POST", "/chat/messages", token=token, data={
        "friend_id": non_friend_id,
        "content": "Test message",
        "message_type": "text"
    })
    
    if response.status_code in [403, 404]:
        print_success("Correctly blocked message to non-friend")
        return True
    else:
        print_error(f"Should have blocked but got: {response.status_code} - {response.text}")
        return False

def test_message_validation(token: str, friend_id: int) -> bool:
    """Test message content validation."""
    print_info("Testing message validation (empty message should fail)...")
    response = make_request("POST", "/chat/messages", token=token, data={
        "friend_id": friend_id,
        "content": "",
        "message_type": "text"
    })
    
    if response.status_code == 422:
        print_success("Correctly rejected empty message")
        return True
    else:
        print_error(f"Should have rejected but got: {response.status_code} - {response.text}")
        return False

def main():
    """Run all tests."""
    print(f"\n{Colors.BLUE}{'='*60}")
    print("CHAT BACKEND COMPREHENSIVE TEST")
    print(f"{'='*60}{Colors.RESET}\n")
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL.replace('/api/v1', '')}/health", timeout=5)
        if response.status_code != 200:
            print_error("Backend server is not responding correctly")
            return
        print_success("Backend server is running")
    except requests.exceptions.RequestException as e:
        print_error(f"Cannot connect to backend server: {e}")
        print_info("Make sure the backend is running on http://localhost:9000")
        return
    
    # Get credentials from user
    print(f"\n{Colors.YELLOW}Please provide login credentials for two users who are friends:{Colors.RESET}")
    print("(These users must already exist and be friends in the database)\n")
    
    username1 = input("User 1 username: ").strip()
    password1 = input("User 1 password: ").strip()
    username2 = input("User 2 username: ").strip()
    password2 = input("User 2 password: ").strip()
    
    # Login both users
    print("\n" + "="*60)
    print("AUTHENTICATION")
    print("="*60)
    user1 = test_login(username1, password1)
    if not user1:
        print_error("Cannot proceed without User 1 login")
        return
    
    user2 = test_login(username2, password2)
    if not user2:
        print_error("Cannot proceed without User 2 login")
        return
    
    global USER1_TOKEN, USER2_TOKEN, USER1_ID, USER2_ID
    USER1_TOKEN = user1["token"]
    USER2_TOKEN = user2["token"]
    USER1_ID = user1["user_id"]
    USER2_ID = user2["user_id"]
    
    # Run tests
    print("\n" + "="*60)
    print("TESTING CHAT FUNCTIONALITY")
    print("="*60)
    
    results = []
    
    # Test 1: Get conversations (should be empty initially)
    print("\n[Test 1] Get Conversations")
    results.append(("Get Conversations", test_get_conversations(USER1_TOKEN)))
    
    # Test 2: Get or create conversation
    print("\n[Test 2] Get/Create Conversation")
    conversation_id = test_get_or_create_conversation(USER1_TOKEN, USER2_ID)
    if conversation_id:
        results.append(("Get/Create Conversation", True))
    else:
        results.append(("Get/Create Conversation", False))
        print_error("Cannot proceed without conversation")
        return
    
    # Test 3: Send message from User 1 to User 2
    print("\n[Test 3] Send Message (User 1 → User 2)")
    message1 = test_send_message(USER1_TOKEN, USER2_ID, f"Hello from User 1! ({datetime.now().strftime('%H:%M:%S')})")
    results.append(("Send Message", message1 is not None))
    
    # Test 4: Get messages for User 2
    print("\n[Test 4] Get Messages (User 2's view)")
    results.append(("Get Messages", test_get_messages(USER2_TOKEN, conversation_id)))
    
    # Test 5: Check unread count for User 2
    print("\n[Test 5] Check Unread Count (User 2)")
    results.append(("Unread Count", test_unread_count(USER2_TOKEN)))
    
    # Test 6: Mark as read
    print("\n[Test 6] Mark as Read (User 2)")
    results.append(("Mark as Read", test_mark_as_read(USER2_TOKEN, conversation_id)))
    
    # Test 7: Check unread count after marking as read
    print("\n[Test 7] Check Unread Count After Read (User 2)")
    results.append(("Unread Count After Read", test_unread_count(USER2_TOKEN)))
    
    # Test 8: Send message from User 2 to User 1
    print("\n[Test 8] Send Message (User 2 → User 1)")
    message2 = test_send_message(USER2_TOKEN, USER1_ID, f"Hello back from User 2! ({datetime.now().strftime('%H:%M:%S')})")
    results.append(("Send Message (Reply)", message2 is not None))
    
    # Test 9: Get conversations list (should now have the conversation)
    print("\n[Test 9] Get Conversations (should show conversation)")
    results.append(("Get Conversations (Updated)", test_get_conversations(USER1_TOKEN)))
    
    # Test 10: Get messages for User 1
    print("\n[Test 10] Get Messages (User 1's view)")
    results.append(("Get Messages (User 1)", test_get_messages(USER1_TOKEN, conversation_id)))
    
    # Test 11: Friendship validation
    print("\n[Test 11] Friendship Validation")
    # Try to send message to a non-existent or non-friend user
    results.append(("Friendship Validation", test_friendship_validation(USER1_TOKEN, 99999)))
    
    # Test 12: Message validation
    print("\n[Test 12] Message Validation")
    results.append(("Message Validation", test_message_validation(USER1_TOKEN, USER2_ID)))
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = f"{Colors.GREEN}✓ PASS{Colors.RESET}" if result else f"{Colors.RED}✗ FAIL{Colors.RESET}"
        print(f"{status} - {test_name}")
    
    print(f"\n{Colors.BLUE}Total: {passed}/{total} tests passed{Colors.RESET}")
    
    if passed == total:
        print(f"\n{Colors.GREEN}All tests passed! 🎉{Colors.RESET}")
    else:
        print(f"\n{Colors.YELLOW}Some tests failed. Please review the errors above.{Colors.RESET}")

if __name__ == "__main__":
    main()

