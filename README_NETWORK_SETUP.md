# Network Setup for Mobile App Testing

## The Issue

When testing on a physical device, the phone needs to connect to your computer's backend server over the local network, not localhost.

## Solution

### 1. Start Backend Server on Network Interface

Instead of:
```bash
uvicorn app.main:app --reload
```

Use:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or use the provided script:
```bash
cd backend
./start_server.sh
```

The `--host 0.0.0.0` makes the server listen on all network interfaces, allowing connections from your phone.

### 2. Configure Mobile App API URL

The mobile app needs to know your computer's IP address on the local network.

**Option A: Use .env file (Recommended)**
Add to `mobile/.env`:
```
API_BASE_URL=http://192.168.1.143:8000
```
(Replace `192.168.1.143` with your actual local network IP)

**Option B: Update AppConstants**
Edit `mobile/lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://192.168.1.143:8000';
```

### 3. Find Your Computer's IP Address

**Linux:**
```bash
ip addr show | grep "inet " | grep -v "127.0.0.1"
```

**Or:**
```bash
hostname -I
```

Look for an IP like `192.168.1.XXX` (your local network IP).

### 4. Firewall

Make sure your firewall allows connections on port 8000:
```bash
# For ufw (Ubuntu/Debian)
sudo ufw allow 8000

# For firewalld (Fedora/RHEL)
sudo firewall-cmd --add-port=8000/tcp --permanent
sudo firewall-cmd --reload
```

### 5. Test Connection

From your phone's browser, try:
```
http://192.168.1.143:8000/health
```

You should see: `{"status":"healthy"}`

## Troubleshooting

- **Connection refused**: Backend not running or wrong IP address
- **Timeout**: Firewall blocking port 8000
- **Can't reach**: Make sure phone and computer are on same WiFi network

