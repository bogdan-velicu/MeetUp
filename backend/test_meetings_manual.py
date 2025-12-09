#!/usr/bin/env python3
"""
Manual testing script for Meetings API endpoints.
Run this after implementing each endpoint to verify it works.

Usage:
    cd backend
    source venv/bin/activate
    python test_meetings_manual.py
"""

import requests
import json
from datetime import datetime, timedelta
from typing import Optional

BASE_URL = "http://127.0.0.1:8000/api/v1"
TEST_EMAIL_1 = "test_meeting1@example.com"
TEST_EMAIL_2 = "test_meeting2@example.com"
TEST_PASSWORD = "testpass123"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_success(message: str):
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")

def print_error(message: str):
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")

def print_info(message: str):
    print(f"{Colors.BLUE}ℹ {message}{Colors.RESET}")

def print_warning(message: str):
    print(f"{Colors.YELLOW}⚠ {message}{Colors.RESET}")

def print_section(title: str):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{title}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}\n")

class MeetingTester:
    def __init__(self):
        self.token1: Optional[str] = None
        self.token2: Optional[str] = None
        self.user1_id: Optional[int] = None
        self.user2_id: Optional[int] = None
        self.meeting_id: Optional[int] = None
        
    def register_user(self, email: str, username: str, password: str) -> tuple[Optional[str], Optional[int]]:
        """Register a new user and return token and user_id."""
        try:
            response = requests.post(
                f"{BASE_URL}/auth/register",
                json={
                    "email": email,
                    "username": username,
                    "password": password,
                    "full_name": f"Test User {username}"
                }
            )
            if response.status_code == 201:
                data = response.json()
                token = data.get("token", {}).get("access_token")
                user_id = data.get("user", {}).get("id")
                return token, user_id
            else:
                print_warning(f"Registration failed (might already exist): {response.status_code}")
                # Try to login instead
                return self.login_user(email, password)
        except Exception as e:
            print_error(f"Registration error: {e}")
            return None, None
    
    def login_user(self, email: str, password: str) -> tuple[Optional[str], Optional[int]]:
        """Login user and return token and user_id."""
        try:
            response = requests.post(
                f"{BASE_URL}/auth/login",
                json={"email": email, "password": password}
            )
            if response.status_code == 200:
                data = response.json()
                token = data.get("token", {}).get("access_token")
                # Get user info
                user_response = requests.get(
                    f"{BASE_URL}/users/me",
                    headers={"Authorization": f"Bearer {token}"}
                )
                if user_response.status_code == 200:
                    user_id = user_response.json().get("id")
                    return token, user_id
            return None, None
        except Exception as e:
            print_error(f"Login error: {e}")
            return None, None
    
    def setup_users(self):
        """Set up test users and make them friends."""
        print_section("Setting up test users")
        
        # Register/Login user 1
        self.token1, self.user1_id = self.register_user(
            TEST_EMAIL_1, "meetinguser1", TEST_PASSWORD
        )
        if not self.token1:
            print_error("Failed to get token for user 1")
            return False
        print_success(f"User 1 authenticated (ID: {self.user1_id})")
        
        # Register/Login user 2
        self.token2, self.user2_id = self.register_user(
            TEST_EMAIL_2, "meetinguser2", TEST_PASSWORD
        )
        if not self.token2:
            print_error("Failed to get token for user 2")
            return False
        print_success(f"User 2 authenticated (ID: {self.user2_id})")
        
        # Make them friends
        print_info("Making users friends...")
        response = requests.post(
            f"{BASE_URL}/friends/{self.user2_id}/request",
            headers={"Authorization": f"Bearer {self.token1}"}
        )
        if response.status_code in [200, 201]:
            # Accept the request
            requests.patch(
                f"{BASE_URL}/friends/{self.user1_id}/accept",
                headers={"Authorization": f"Bearer {self.token2}"}
            )
            print_success("Users are now friends")
        else:
            print_warning(f"Friend request might already exist: {response.status_code}")
        
        return True
    
    def test_create_meeting(self):
        """Test POST /api/v1/meetings"""
        print_section("Testing: Create Meeting (POST /api/v1/meetings)")
        
        if not self.token1 or not self.user2_id:
            print_error("Users not set up. Run setup_users() first.")
            return False
        
        scheduled_at = (datetime.now() + timedelta(days=1)).isoformat()
        
        meeting_data = {
            "title": "Test Meeting",
            "description": "This is a test meeting",
            "latitude": "44.4268",
            "longitude": "26.1025",
            "address": "Bucharest, Romania",
            "scheduled_at": scheduled_at,
            "participant_ids": [self.user2_id]
        }
        
        try:
            response = requests.post(
                f"{BASE_URL}/meetings",
                headers={
                    "Authorization": f"Bearer {self.token1}",
                    "Content-Type": "application/json"
                },
                json=meeting_data
            )
            
            print_info(f"Status Code: {response.status_code}")
            print_info(f"Response: {json.dumps(response.json(), indent=2)}")
            
            if response.status_code == 201:
                data = response.json()
                self.meeting_id = data.get("id")
                print_success(f"Meeting created successfully (ID: {self.meeting_id})")
                return True
            else:
                print_error(f"Failed to create meeting: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error creating meeting: {e}")
            return False
    
    def test_list_meetings(self):
        """Test GET /api/v1/meetings"""
        print_section("Testing: List Meetings (GET /api/v1/meetings)")
        
        if not self.token1:
            print_error("User not authenticated")
            return False
        
        try:
            response = requests.get(
                f"{BASE_URL}/meetings",
                headers={"Authorization": f"Bearer {self.token1}"}
            )
            
            print_info(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                meetings = response.json()
                print_success(f"Retrieved {len(meetings)} meetings")
                print_info(f"Meetings: {json.dumps(meetings, indent=2)}")
                return True
            else:
                print_error(f"Failed to list meetings: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error listing meetings: {e}")
            return False
    
    def test_get_meeting(self):
        """Test GET /api/v1/meetings/{id}"""
        print_section("Testing: Get Meeting Details (GET /api/v1/meetings/{id})")
        
        if not self.token1 or not self.meeting_id:
            print_error("Meeting ID not available. Create a meeting first.")
            return False
        
        try:
            response = requests.get(
                f"{BASE_URL}/meetings/{self.meeting_id}",
                headers={"Authorization": f"Bearer {self.token1}"}
            )
            
            print_info(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                meeting = response.json()
                print_success("Meeting retrieved successfully")
                print_info(f"Meeting: {json.dumps(meeting, indent=2)}")
                return True
            else:
                print_error(f"Failed to get meeting: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error getting meeting: {e}")
            return False
    
    def test_update_meeting(self):
        """Test PATCH /api/v1/meetings/{id}"""
        print_section("Testing: Update Meeting (PATCH /api/v1/meetings/{id})")
        
        if not self.token1 or not self.meeting_id:
            print_error("Meeting ID not available")
            return False
        
        update_data = {
            "title": "Updated Test Meeting",
            "description": "This meeting has been updated"
        }
        
        try:
            response = requests.patch(
                f"{BASE_URL}/meetings/{self.meeting_id}",
                headers={
                    "Authorization": f"Bearer {self.token1}",
                    "Content-Type": "application/json"
                },
                json=update_data
            )
            
            print_info(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                meeting = response.json()
                print_success("Meeting updated successfully")
                print_info(f"Updated meeting: {json.dumps(meeting, indent=2)}")
                return True
            else:
                print_error(f"Failed to update meeting: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error updating meeting: {e}")
            return False
    
    def test_delete_meeting(self):
        """Test DELETE /api/v1/meetings/{id}"""
        print_section("Testing: Delete Meeting (DELETE /api/v1/meetings/{id})")
        
        if not self.token1 or not self.meeting_id:
            print_error("Meeting ID not available")
            return False
        
        try:
            response = requests.delete(
                f"{BASE_URL}/meetings/{self.meeting_id}",
                headers={"Authorization": f"Bearer {self.token1}"}
            )
            
            print_info(f"Status Code: {response.status_code}")
            
            if response.status_code in [200, 204]:
                print_success("Meeting deleted successfully")
                return True
            else:
                print_error(f"Failed to delete meeting: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error deleting meeting: {e}")
            return False
    
    def test_list_invitations(self):
        """Test GET /api/v1/invitations"""
        print_section("Testing: List Invitations (GET /api/v1/invitations)")
        
        if not self.token2:
            print_error("User 2 not authenticated")
            return False
        
        try:
            response = requests.get(
                f"{BASE_URL}/invitations",
                headers={"Authorization": f"Bearer {self.token2}"}
            )
            
            print_info(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                invitations = response.json()
                print_success(f"Retrieved {len(invitations)} invitations")
                print_info(f"Invitations: {json.dumps(invitations, indent=2)}")
                return True
            else:
                print_error(f"Failed to list invitations: {response.text}")
                return False
        except Exception as e:
            print_error(f"Error listing invitations: {e}")
            return False
    
    def run_all_tests(self):
        """Run all tests in sequence."""
        print(f"\n{Colors.BOLD}{'='*60}{Colors.RESET}")
        print(f"{Colors.BOLD}MEETINGS API MANUAL TEST SUITE{Colors.RESET}")
        print(f"{Colors.BOLD}{'='*60}{Colors.RESET}\n")
        
        print_info("Make sure the backend server is running on http://127.0.0.1:8000")
        print_info("Press Enter to continue or Ctrl+C to cancel...")
        try:
            input()
        except KeyboardInterrupt:
            print("\nTest cancelled.")
            return
        
        results = {}
        
        # Setup
        if not self.setup_users():
            print_error("Failed to set up users. Cannot continue.")
            return
        
        # Test endpoints as they're implemented
        results["create_meeting"] = self.test_create_meeting()
        results["list_meetings"] = self.test_list_meetings()
        results["get_meeting"] = self.test_get_meeting()
        results["update_meeting"] = self.test_update_meeting()
        results["list_invitations"] = self.test_list_invitations()
        # Don't delete by default - comment out if you want to test deletion
        # results["delete_meeting"] = self.test_delete_meeting()
        
        # Summary
        print_section("Test Summary")
        for test_name, passed in results.items():
            if passed:
                print_success(f"{test_name}: PASSED")
            else:
                print_error(f"{test_name}: FAILED")
        
        passed_count = sum(1 for v in results.values() if v)
        total_count = len(results)
        print(f"\n{Colors.BOLD}Total: {passed_count}/{total_count} tests passed{Colors.RESET}\n")

if __name__ == "__main__":
    tester = MeetingTester()
    tester.run_all_tests()

