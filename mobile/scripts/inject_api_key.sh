#!/bin/bash
# Script to inject Google Maps API key from .env into AndroidManifest.xml

ENV_FILE=".env"
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Extract GOOGLE_CLOUD_KEY from .env
API_KEY=$(grep "GOOGLE_CLOUD_KEY" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)

if [ -z "$API_KEY" ]; then
    echo "Error: GOOGLE_CLOUD_KEY not found in .env"
    exit 1
fi

# Replace the API key in AndroidManifest.xml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/android:value=\".*\"/android:value=\"$API_KEY\"/" "$MANIFEST_FILE"
else
    # Linux
    sed -i "s/android:value=\".*\"/android:value=\"$API_KEY\"/" "$MANIFEST_FILE"
fi

echo "✓ Google Maps API key injected into AndroidManifest.xml"

