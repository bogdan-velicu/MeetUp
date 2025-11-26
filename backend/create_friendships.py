#!/usr/bin/env python3
"""
Script to create friendships between your account and mock users.
Run this script and enter your password when prompted.
"""

import requests
import getpass

def main():
    print('🤝 Adding mock users as friends to your account...')
    
    # Your account details
    your_email = 'bboodd24@gmail.com'
    your_password = getpass.getpass('Enter your password: ')
    
    try:
        # Login to get your token
        login_data = {'email': your_email, 'password': your_password}
        response = requests.post('http://127.0.0.1:8000/api/v1/auth/login', json=login_data, timeout=10)
        
        if response.status_code == 200:
            your_token = response.json()['token']['access_token']
            your_headers = {'Authorization': f'Bearer {your_token}'}
            print('✅ Successfully logged in!')
            
            # Get the mock users' IDs and send friend requests
            mock_usernames = ['alice_smith', 'bob_jones', 'charlie_brown', 'diana_prince']
            friend_requests_sent = []
            
            for username in mock_usernames:
                try:
                    # Search for the user
                    search_response = requests.get(
                        f'http://127.0.0.1:8000/api/v1/users/search?q={username}',
                        headers=your_headers, timeout=10
                    )
                    
                    if search_response.status_code == 200:
                        users = search_response.json()
                        if users:
                            user_id = users[0]['id']
                            
                            # Send friend request
                            friend_response = requests.post(
                                f'http://127.0.0.1:8000/api/v1/friends/{user_id}/request',
                                headers=your_headers, timeout=10
                            )
                            
                            if friend_response.status_code == 201:
                                print(f'✅ Sent friend request to {users[0]["full_name"]} (@{username})')
                                friend_requests_sent.append({
                                    'id': user_id, 
                                    'username': username, 
                                    'full_name': users[0]["full_name"]
                                })
                            else:
                                print(f'❌ Failed to send friend request to {username}: {friend_response.text}')
                        else:
                            print(f'❌ User {username} not found in search')
                    else:
                        print(f'❌ Search failed for {username}: {search_response.text}')
                        
                except Exception as e:
                    print(f'❌ Error processing {username}: {e}')
            
            print(f'\n📤 Sent {len(friend_requests_sent)} friend requests!')
            
            # Now auto-accept the friend requests by logging in as each mock user
            print('\n🤝 Auto-accepting friend requests...')
            
            mock_users = [
                {'username': 'alice_smith', 'email': 'alice@example.com'},
                {'username': 'bob_jones', 'email': 'bob@example.com'},
                {'username': 'charlie_brown', 'email': 'charlie@example.com'},
                {'username': 'diana_prince', 'email': 'diana@example.com'}
            ]
            
            accepted_count = 0
            for mock_user in mock_users:
                try:
                    # Login as mock user
                    mock_login = {
                        'email': mock_user['email'],
                        'password': 'password123'
                    }
                    mock_response = requests.post('http://127.0.0.1:8000/api/v1/auth/login', 
                                                json=mock_login, timeout=10)
                    
                    if mock_response.status_code == 200:
                        mock_token = mock_response.json()['token']['access_token']
                        mock_headers = {'Authorization': f'Bearer {mock_token}'}
                        
                        # Accept friend request from you (user ID 1)
                        your_user_id = 1  # Assuming you're user ID 1
                        accept_response = requests.patch(
                            f'http://127.0.0.1:8000/api/v1/friends/{your_user_id}/accept',
                            headers=mock_headers, timeout=10
                        )
                        
                        if accept_response.status_code == 200:
                            print(f'✅ {mock_user["username"]} accepted your friend request!')
                            accepted_count += 1
                        else:
                            print(f'❌ Failed to accept from {mock_user["username"]}: {accept_response.text}')
                    else:
                        print(f'❌ Failed to login as {mock_user["username"]}: {mock_response.text}')
                                    
                except Exception as e:
                    print(f'❌ Error with {mock_user["username"]}: {e}')
            
            print(f'\n🎉 Successfully created {accepted_count} friendships!')
            print('\n📱 Now restart your Flutter app or refresh the friends/map screens to see your new friends!')
            print('\nYour friends should appear as colored markers on the map:')
            print('  🟢 Alice Smith - Available (Old Town)')
            print('  🔴 Bob Jones - Busy (Herastrau Park)')  
            print('  🟠 Charlie Brown - Away (Unirii Square)')
            print('  🟢 Diana Prince - Available (Aviatorilor)')
            
        else:
            print(f'❌ Login failed: {response.text}')
            
    except Exception as e:
        print(f'❌ Error: {e}')

if __name__ == '__main__':
    main()
