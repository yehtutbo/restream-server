#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Facebook RTMPS Setup Script ===${NC}"
echo ""

# Get VPS IP
VPS_IP=$(curl -s ifconfig.me || echo "localhost")

# Check if Docker is running
if ! docker ps &>/dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Get Facebook Stream Key
echo -e "${YELLOW}Step 1: Get your Facebook Stream Key${NC}"
echo "1. Go to https://www.facebook.com/live/create"
echo "2. Click 'Streaming via RTMP'"
echo "3. Copy the Stream Key"
echo ""
read -p "Enter your Facebook Stream Key: " FB_KEY

if [ -z "$FB_KEY" ]; then
    echo -e "${RED}❌ Stream key cannot be empty${NC}"
    exit 1
fi

# Create output configuration
echo ""
echo -e "${YELLOW}Step 2: Configuring Facebook output...${NC}"

cat > facebook-output.json <<EOF
{
  "name": "Facebook Live",
  "type": "rtmp",
  "url": "rtmps://rtmp-api.facebook.com:443/rtmp/",
  "streamKey": "$FB_KEY",
  "settings": {
    "videoBitrate": 6000,
    "audioBitrate": 128,
    "resolution": "1920x1080",
    "framerate": 30,
    "keyframeInterval": 2,
    "codec": "h264",
    "profile": "high",
    "tune": "zerolatency"
  },
  "enabled": true,
  "autoStart": false
}
EOF

echo -e "${GREEN}✅ Facebook output config created: facebook-output.json${NC}"

# Add output via API
echo ""
echo -e "${YELLOW}Step 3: Adding Facebook output to Restreamer...${NC}"

RESPONSE=$(curl -s -X POST -u admin:ChangeMe123! \
  -H "Content-Type: application/json" \
  -d @facebook-output.json \
  http://localhost:8080/api/v1/outputs)

if echo $RESPONSE | grep -q "id"; then
    OUTPUT_ID=$(echo $RESPONSE | jq -r '.id')
    echo -e "${GREEN}✅ Facebook output added successfully!${NC}"
    echo -e "Output ID: $OUTPUT_ID"
else
    echo -e "${RED}❌ Failed to add Facebook output${NC}"
    echo $RESPONSE | jq '.'
    exit 1
fi

# Show connection info
echo ""
echo -e "${GREEN}=== Facebook RTMPS Connection Info ===${NC}"
echo -e "📤 Output URL: ${YELLOW}rtmps://rtmp-api.facebook.com:443/rtmp/${NC}"
echo -e "🔑 Stream Key: ${YELLOW}${FB_KEY}${NC}"
echo -e "🌐 Server IP: ${YELLOW}${VPS_IP}${NC}"
echo -e "🔗 RTMP Ingest: ${YELLOW}rtmp://${VPS_IP}:1935/live/YOUR_KEY${NC}"
echo ""
echo -e "${GREEN}Recommended Settings:${NC}"
echo -e "  • Resolution: 1920x1080 (1080p) or 1280x720 (720p)"
echo -e "  • Bitrate: 4500-6000 Kbps"
echo -e "  • Framerate: 30 or 60 fps"
echo -e "  • Keyframe Interval: 2 seconds"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Open Web UI: http://${VPS_IP}:8080"
echo "2. Login: admin / ChangeMe123!"
echo "3. Go to Outputs → Facebook Live"
echo "4. Click 'Start' to begin streaming to Facebook"
echo ""
echo -e "${GREEN}Test Connection:${NC}"
echo "curl -I https://rtmp-api.facebook.com"