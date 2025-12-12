#!/usr/bin/env python3
"""
Test script for Points System
Tests points awarding, history, and meeting confirmation
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000/api/v1"

def login_user(email, password):
    """Login and return token"""
    response = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    if response.status_code == 200:
        return response.json()["token"]["access_token"]
    return None

def get_headers(token):
    """Get request headers with auth token"""
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

def test_points_summary(token):
    """Test getting points summary"""
    print("\n=== Testing Points Summary ===")
    response = requests.get(f"{BASE_URL}/points/summary", headers=get_headers(token))
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Points Summary:")
        print(f"   Total Points: {data['total_points']}")
        print(f"   Breakdown: {json.dumps(data.get('breakdown', {}), indent=2)}")
        return True
    else:
        print(f"❌ Failed: {response.status_code} - {response.text}")
        return False

def test_points_history(token):
    """Test getting points history"""
    print("\n=== Testing Points History ===")
    response = requests.get(f"{BASE_URL}/points/history?limit=10", headers=get_headers(token))
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Points History:")
        print(f"   Transactions: {len(data['transactions'])}")
        for txn in data['transactions'][:5]:
            print(f"   - {txn['transaction_type']}: {txn['points']} points ({txn.get('description', 'N/A')})")
        return True
    else:
        print(f"❌ Failed: {response.status_code} - {response.text}")
        return False

def test_meeting_confirmation(token, meeting_id):
    """Test meeting confirmation and points awarding"""
    print(f"\n=== Testing Meeting Confirmation (Meeting ID: {meeting_id}) ===")
    response = requests.post(
        f"{BASE_URL}/points/meetings/{meeting_id}/confirm",
        headers=get_headers(token)
    )
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Meeting Confirmed!")
        print(f"   Points Awarded: {data['points']}")
        print(f"   New Total: {data['total_points']}")
        print(f"   Transaction ID: {data['transaction_id']}")
        return True
    else:
        print(f"❌ Failed: {response.status_code} - {response.text}")
        return False

def get_user_meetings(token):
    """Get user's meetings"""
    response = requests.get(f"{BASE_URL}/meetings?filter_type=all", headers=get_headers(token))
    if response.status_code == 200:
        return response.json()
    return []

def main():
    print("=" * 60)
    print("Points System Test")
    print("=" * 60)
    
    # Login as Alice
    print("\n1. Logging in as Alice...")
    alice_token = login_user("alice@example.com", "password123")
    if not alice_token:
        print("❌ Failed to login as Alice")
        return
    
    print("✅ Logged in as Alice")
    
    # Test points summary
    test_points_summary(alice_token)
    
    # Test points history
    test_points_history(alice_token)
    
    # Get a meeting to confirm
    print("\n=== Getting Meetings ===")
    meetings = get_user_meetings(alice_token)
    if meetings:
        print(f"✅ Found {len(meetings)} meetings")
        # Find a pending meeting where Alice is a participant (not organizer)
        for meeting in meetings:
            if meeting.get('status') == 'pending':
                # Check if Alice is a participant
                participants = meeting.get('participants', [])
                organizer_id = meeting.get('organizer_id')
                alice_id = 5  # Assuming Alice's ID is 5
                
                # Skip if Alice is organizer
                if organizer_id == alice_id:
                    continue
                
                # Check if Alice is a participant
                is_participant = any(p.get('user_id') == alice_id for p in participants)
                if is_participant:
                    print(f"\n   Found meeting: {meeting.get('title', 'Untitled')} (ID: {meeting['id']})")
                    test_meeting_confirmation(alice_token, meeting['id'])
                    break
        else:
            print("⚠️  No suitable meetings found for confirmation test")
            print("   (Need a pending meeting where Alice is a participant, not organizer)")
    else:
        print("⚠️  No meetings found. Create a meeting first to test confirmation.")
    
    # Test points summary again to see updated total
    print("\n=== Final Points Summary ===")
    test_points_summary(alice_token)
    test_points_history(alice_token)
    
    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()

