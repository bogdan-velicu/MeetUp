#!/usr/bin/env python3
"""
MeetUp CLI Tool - Interactive console application for testing and controlling the MeetUp app.

This tool allows you to:
- Login as different users
- Manage friends (send requests, accept, decline, remove)
- Manage meetings (create, update, delete, add participants)
- Manage invitations (list, accept, decline)
- Update locations
- Search users
- And much more!

Usage:
    python cli_tool.py
    python cli_tool.py --help
"""

import requests
import json
from typing import Optional, Dict, List, Any
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.text import Text
from rich import box
import sys
import os

# Configuration
BASE_URL = os.getenv("MEETUP_API_URL", "http://127.0.0.1:8000/api/v1")
console = Console()

class MeetUpCLI:
    def __init__(self):
        self.base_url = BASE_URL
        self.current_user: Optional[Dict] = None
        self.current_token: Optional[str] = None
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})
    
    def _make_request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """Make an API request with authentication."""
        url = f"{self.base_url}{endpoint}"
        if self.current_token:
            self.session.headers.update({"Authorization": f"Bearer {self.current_token}"})
        
        try:
            if method.upper() == "GET":
                response = self.session.get(url, **kwargs)
            elif method.upper() == "POST":
                response = self.session.post(url, **kwargs)
            elif method.upper() == "PATCH":
                response = self.session.patch(url, **kwargs)
            elif method.upper() == "DELETE":
                response = self.session.delete(url, **kwargs)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            return response
        except requests.exceptions.ConnectionError:
            console.print("[red]❌ Cannot connect to server. Is the backend running?[/red]")
            return None
        except Exception as e:
            console.print(f"[red]❌ Error: {e}[/red]")
            return None
    
    def login(self, email: str = None, password: str = None) -> bool:
        """Login as a user."""
        if not email:
            email = Prompt.ask("Email")
        if not password:
            password = Prompt.ask("Password", password=True)
        
        response = self._make_request("POST", "/auth/login", json={
            "email": email,
            "password": password
        })
        
        if response and response.status_code == 200:
            data = response.json()
            self.current_token = data["token"]["access_token"]
            self.current_user = data["user"]
            console.print(f"[green]✅ Logged in as {self.current_user['username']} (ID: {self.current_user['id']})[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Login failed") if response else "Connection error"
            console.print(f"[red]❌ Login failed: {error_msg}[/red]")
            return False
    
    def get_current_user_info(self) -> Optional[Dict]:
        """Get current user information."""
        response = self._make_request("GET", "/auth/me")
        if response and response.status_code == 200:
            return response.json()
        return None
    
    def search_users(self, query: str) -> List[Dict]:
        """Search for users."""
        response = self._make_request("GET", f"/users/search?q={query}&limit=20")
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def list_friends(self, close_friends_only: bool = False) -> List[Dict]:
        """List current user's friends."""
        endpoint = f"/friends?close_friends_only={str(close_friends_only).lower()}"
        response = self._make_request("GET", endpoint)
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def get_pending_requests(self) -> List[Dict]:
        """Get pending friend requests (incoming)."""
        response = self._make_request("GET", "/friends/requests/pending")
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def get_sent_requests(self) -> List[Dict]:
        """Get sent friend requests (outgoing)."""
        response = self._make_request("GET", "/friends/requests/sent")
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def send_friend_request(self, friend_id: int) -> bool:
        """Send a friend request."""
        response = self._make_request("POST", f"/friends/{friend_id}/request")
        if response and response.status_code == 201:
            console.print(f"[green]✅ Friend request sent to user {friend_id}[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def accept_friend_request(self, friend_id: int) -> bool:
        """Accept a friend request."""
        response = self._make_request("PATCH", f"/friends/{friend_id}/accept")
        if response and response.status_code == 200:
            console.print(f"[green]✅ Friend request accepted from user {friend_id}[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def decline_friend_request(self, friend_id: int) -> bool:
        """Decline a friend request."""
        response = self._make_request("PATCH", f"/friends/{friend_id}/decline")
        if response and response.status_code == 204:
            console.print(f"[green]✅ Friend request declined from user {friend_id}[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def remove_friend(self, friend_id: int) -> bool:
        """Remove a friend."""
        response = self._make_request("DELETE", f"/friends/{friend_id}")
        if response and response.status_code == 204:
            console.print(f"[green]✅ Friend removed (ID: {friend_id})[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def list_meetings(self, filter_type: str = "all") -> List[Dict]:
        """List meetings."""
        response = self._make_request("GET", f"/meetings?filter_type={filter_type}")
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def get_meeting(self, meeting_id: int) -> Optional[Dict]:
        """Get meeting details."""
        response = self._make_request("GET", f"/meetings/{meeting_id}")
        if response and response.status_code == 200:
            return response.json()
        return None
    
    def create_meeting(self, title: str, description: str, location: str, 
                      scheduled_at: str, participant_ids: List[int] = None) -> Optional[Dict]:
        """Create a meeting."""
        data = {
            "title": title,
            "description": description,
            "location": location,
            "scheduled_at": scheduled_at
        }
        if participant_ids:
            data["participant_ids"] = participant_ids
        
        response = self._make_request("POST", "/meetings", json=data)
        if response and response.status_code == 201:
            meeting = response.json()
            console.print(f"[green]✅ Meeting created: {meeting['title']} (ID: {meeting['id']})[/green]")
            return meeting
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return None
    
    def update_meeting(self, meeting_id: int, **kwargs) -> Optional[Dict]:
        """Update a meeting."""
        response = self._make_request("PATCH", f"/meetings/{meeting_id}", json=kwargs)
        if response and response.status_code == 200:
            console.print(f"[green]✅ Meeting updated[/green]")
            return response.json()
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return None
    
    def delete_meeting(self, meeting_id: int) -> bool:
        """Delete a meeting."""
        response = self._make_request("DELETE", f"/meetings/{meeting_id}")
        if response and response.status_code == 204:
            console.print(f"[green]✅ Meeting deleted[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def add_participants_to_meeting(self, meeting_id: int, participant_ids: List[int]) -> Optional[Dict]:
        """Add participants to a meeting."""
        response = self._make_request("POST", f"/meetings/{meeting_id}/participants", json=participant_ids)
        if response and response.status_code == 200:
            console.print(f"[green]✅ Participants added to meeting[/green]")
            return response.json()
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return None
    
    def list_invitations(self) -> List[Dict]:
        """List pending invitations."""
        response = self._make_request("GET", "/invitations")
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def get_invitation(self, invitation_id: int) -> Optional[Dict]:
        """Get invitation details."""
        response = self._make_request("GET", f"/invitations/{invitation_id}")
        if response and response.status_code == 200:
            return response.json()
        return None
    
    def accept_invitation(self, invitation_id: int) -> bool:
        """Accept an invitation."""
        response = self._make_request("PATCH", f"/invitations/{invitation_id}/accept")
        if response and response.status_code == 200:
            console.print(f"[green]✅ Invitation accepted[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def decline_invitation(self, invitation_id: int) -> bool:
        """Decline an invitation."""
        response = self._make_request("PATCH", f"/invitations/{invitation_id}/decline")
        if response and response.status_code == 200:
            console.print(f"[green]✅ Invitation declined[/green]")
            return True
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return False
    
    def update_location(self, latitude: float, longitude: float, accuracy_m: float = 10.0) -> Optional[Dict]:
        """Update user location."""
        data = {
            "latitude": latitude,
            "longitude": longitude,
            "accuracy_m": accuracy_m
        }
        response = self._make_request("PATCH", "/location/update", json=data)
        if response and response.status_code == 200:
            console.print(f"[green]✅ Location updated[/green]")
            return response.json()
        else:
            error_msg = response.json().get("detail", "Failed") if response else "Connection error"
            console.print(f"[red]❌ Failed: {error_msg}[/red]")
            return None
    
    def get_friends_locations(self, close_friends_only: bool = False) -> List[Dict]:
        """Get friends' locations."""
        endpoint = f"/location/friends/locations?close_friends_only={str(close_friends_only).lower()}"
        response = self._make_request("GET", endpoint)
        if response and response.status_code == 200:
            return response.json()
        return []
    
    def display_table(self, data: List[Dict], title: str = "Results"):
        """Display data in a formatted table."""
        if not data:
            console.print(f"[yellow]No {title.lower()} found[/yellow]")
            return
        
        table = Table(title=title, box=box.ROUNDED, show_header=True, header_style="bold magenta")
        
        # Determine columns from first item
        if data:
            columns = list(data[0].keys())
            for col in columns:
                table.add_column(col, overflow="fold")
            
            for item in data:
                row = [str(item.get(col, "")) for col in columns]
                table.add_row(*row)
        
        console.print(table)
    
    def display_meeting(self, meeting: Dict):
        """Display meeting details in a formatted way."""
        panel_content = f"""
[bold]Title:[/bold] {meeting.get('title', 'N/A')}
[bold]Description:[/bold] {meeting.get('description', 'N/A')}
[bold]Location:[/bold] {meeting.get('location', 'N/A')}
[bold]Organizer:[/bold] {meeting.get('organizer', {}).get('username', 'N/A')}
[bold]Scheduled At:[/bold] {meeting.get('scheduled_at', 'N/A')}
[bold]Status:[/bold] {meeting.get('status', 'N/A')}
[bold]Participants:[/bold] {meeting.get('participant_count', 0)}
"""
        console.print(Panel(panel_content, title="Meeting Details", border_style="blue"))
        
        if meeting.get('participants'):
            self.display_table(meeting['participants'], "Participants")
    
    def run_interactive(self):
        """Run the interactive CLI."""
        console.print(Panel.fit(
            "[bold cyan]MeetUp CLI Tool[/bold cyan]\n"
            "Interactive console for testing and controlling the MeetUp app",
            border_style="cyan"
        ))
        
        # Check if logged in
        if not self.current_user:
            console.print("[yellow]⚠️  You need to login first[/yellow]")
            if not self.login():
                return
        
        while True:
            console.print("\n" + "="*60)
            user_info = self.get_current_user_info()
            if user_info:
                console.print(f"[cyan]Logged in as:[/cyan] [bold]{user_info['username']}[/bold] (ID: {user_info['id']})")
            
            console.print("\n[bold]Main Menu:[/bold]")
            console.print("  [1] Friends Management")
            console.print("  [2] Meetings Management")
            console.print("  [3] Invitations Management")
            console.print("  [4] Location Management")
            console.print("  [5] User Search")
            console.print("  [6] Switch User (Login)")
            console.print("  [0] Exit")
            
            choice = Prompt.ask("\nSelect option", default="0")
            
            if choice == "0":
                console.print("[yellow]Goodbye![/yellow]")
                break
            elif choice == "1":
                self._friends_menu()
            elif choice == "2":
                self._meetings_menu()
            elif choice == "3":
                self._invitations_menu()
            elif choice == "4":
                self._location_menu()
            elif choice == "5":
                self._search_menu()
            elif choice == "6":
                self.login()
            else:
                console.print("[red]Invalid option[/red]")
    
    def _friends_menu(self):
        """Friends management menu."""
        while True:
            console.print("\n[bold cyan]Friends Management:[/bold cyan]")
            console.print("  [1] List Friends")
            console.print("  [2] List Pending Requests (Incoming)")
            console.print("  [3] List Sent Requests (Outgoing)")
            console.print("  [4] Send Friend Request")
            console.print("  [5] Accept Friend Request")
            console.print("  [6] Decline Friend Request")
            console.print("  [7] Remove Friend")
            console.print("  [0] Back")
            
            choice = Prompt.ask("\nSelect option", default="0")
            
            if choice == "0":
                break
            elif choice == "1":
                friends = self.list_friends()
                self.display_table(friends, "Friends")
            elif choice == "2":
                requests = self.get_pending_requests()
                self.display_table(requests, "Pending Friend Requests")
            elif choice == "3":
                requests = self.get_sent_requests()
                self.display_table(requests, "Sent Friend Requests")
            elif choice == "4":
                friend_id = int(Prompt.ask("Friend ID"))
                self.send_friend_request(friend_id)
            elif choice == "5":
                friend_id = int(Prompt.ask("Friend ID (who sent the request)"))
                self.accept_friend_request(friend_id)
            elif choice == "6":
                friend_id = int(Prompt.ask("Friend ID (who sent the request)"))
                self.decline_friend_request(friend_id)
            elif choice == "7":
                friend_id = int(Prompt.ask("Friend ID to remove"))
                if Confirm.ask("Are you sure?"):
                    self.remove_friend(friend_id)
    
    def _meetings_menu(self):
        """Meetings management menu."""
        while True:
            console.print("\n[bold cyan]Meetings Management:[/bold cyan]")
            console.print("  [1] List Meetings (all)")
            console.print("  [2] List Meetings (organized)")
            console.print("  [3] List Meetings (invited)")
            console.print("  [4] Get Meeting Details")
            console.print("  [5] Create Meeting")
            console.print("  [6] Update Meeting")
            console.print("  [7] Delete Meeting")
            console.print("  [8] Add Participants to Meeting")
            console.print("  [0] Back")
            
            choice = Prompt.ask("\nSelect option", default="0")
            
            if choice == "0":
                break
            elif choice == "1":
                meetings = self.list_meetings("all")
                self.display_table(meetings, "All Meetings")
            elif choice == "2":
                meetings = self.list_meetings("organized")
                self.display_table(meetings, "Organized Meetings")
            elif choice == "3":
                meetings = self.list_meetings("invited")
                self.display_table(meetings, "Invited Meetings")
            elif choice == "4":
                meeting_id = int(Prompt.ask("Meeting ID"))
                meeting = self.get_meeting(meeting_id)
                if meeting:
                    self.display_meeting(meeting)
            elif choice == "5":
                title = Prompt.ask("Title")
                description = Prompt.ask("Description")
                location = Prompt.ask("Location")
                scheduled_at = Prompt.ask("Scheduled At (ISO format, e.g., 2025-12-10T15:00:00)")
                participants = Prompt.ask("Participant IDs (comma-separated, or leave empty)", default="")
                participant_ids = [int(x.strip()) for x in participants.split(",") if x.strip()] if participants else None
                self.create_meeting(title, description, location, scheduled_at, participant_ids)
            elif choice == "6":
                meeting_id = int(Prompt.ask("Meeting ID"))
                console.print("Leave empty to skip a field")
                title = Prompt.ask("Title (new)", default="")
                description = Prompt.ask("Description (new)", default="")
                location = Prompt.ask("Location (new)", default="")
                scheduled_at = Prompt.ask("Scheduled At (new, ISO format)", default="")
                update_data = {}
                if title: update_data["title"] = title
                if description: update_data["description"] = description
                if location: update_data["location"] = location
                if scheduled_at: update_data["scheduled_at"] = scheduled_at
                if update_data:
                    self.update_meeting(meeting_id, **update_data)
            elif choice == "7":
                meeting_id = int(Prompt.ask("Meeting ID"))
                if Confirm.ask("Are you sure?"):
                    self.delete_meeting(meeting_id)
            elif choice == "8":
                meeting_id = int(Prompt.ask("Meeting ID"))
                participants = Prompt.ask("Participant IDs (comma-separated)")
                participant_ids = [int(x.strip()) for x in participants.split(",") if x.strip()]
                self.add_participants_to_meeting(meeting_id, participant_ids)
    
    def _invitations_menu(self):
        """Invitations management menu."""
        while True:
            console.print("\n[bold cyan]Invitations Management:[/bold cyan]")
            console.print("  [1] List Invitations")
            console.print("  [2] Get Invitation Details")
            console.print("  [3] Accept Invitation")
            console.print("  [4] Decline Invitation")
            console.print("  [0] Back")
            
            choice = Prompt.ask("\nSelect option", default="0")
            
            if choice == "0":
                break
            elif choice == "1":
                invitations = self.list_invitations()
                self.display_table(invitations, "Pending Invitations")
            elif choice == "2":
                invitation_id = int(Prompt.ask("Invitation ID (meeting_id)"))
                invitation = self.get_invitation(invitation_id)
                if invitation:
                    self.display_meeting(invitation.get("meeting", {}))
            elif choice == "3":
                invitation_id = int(Prompt.ask("Invitation ID (meeting_id)"))
                self.accept_invitation(invitation_id)
            elif choice == "4":
                invitation_id = int(Prompt.ask("Invitation ID (meeting_id)"))
                self.decline_invitation(invitation_id)
    
    def _location_menu(self):
        """Location management menu."""
        while True:
            console.print("\n[bold cyan]Location Management:[/bold cyan]")
            console.print("  [1] Update My Location")
            console.print("  [2] Get Friends Locations")
            console.print("  [0] Back")
            
            choice = Prompt.ask("\nSelect option", default="0")
            
            if choice == "0":
                break
            elif choice == "1":
                lat = float(Prompt.ask("Latitude"))
                lon = float(Prompt.ask("Longitude"))
                accuracy = float(Prompt.ask("Accuracy (meters)", default="10.0"))
                self.update_location(lat, lon, accuracy)
            elif choice == "2":
                locations = self.get_friends_locations()
                self.display_table(locations, "Friends Locations")
    
    def _search_menu(self):
        """User search menu."""
        query = Prompt.ask("Search query (username or email)")
        users = self.search_users(query)
        self.display_table(users, "Search Results")
        
        if users:
            user_id = Prompt.ask("\nEnter user ID to send friend request (or press Enter to skip)", default="")
            if user_id:
                try:
                    self.send_friend_request(int(user_id))
                except ValueError:
                    console.print("[red]Invalid user ID[/red]")


def main():
    """Main entry point."""
    cli = MeetUpCLI()
    
    # Check if server is reachable
    try:
        response = requests.get(f"{BASE_URL.replace('/api/v1', '')}/health", timeout=2)
        if response.status_code != 200:
            console.print("[yellow]⚠️  Server health check failed, but continuing...[/yellow]")
    except:
        console.print("[yellow]⚠️  Cannot reach server. Make sure the backend is running.[/yellow]")
        if not Confirm.ask("Continue anyway?"):
            return
    
    cli.run_interactive()


if __name__ == "__main__":
    main()

