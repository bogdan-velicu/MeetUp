#!/bin/bash
# Script to start the backend server accessible from network

cd "$(dirname "$0")"
source venv/bin/activate

# Get local network IP (optional - you can hardcode it)
# LOCAL_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)

# Start server on 0.0.0.0 to accept connections from network
# Replace 192.168.1.143 with your actual local network IP if needed
uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload

