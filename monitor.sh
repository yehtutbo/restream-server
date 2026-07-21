#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
API_URL="http://localhost:8080/api/v1"
AUTH="admin:ChangeMe123!"
REFRESH_INTERVAL=5  # seconds

# Trap Ctrl+C
trap "echo -e '\n${GREEN}Monitoring stopped${NC}'; exit 0" INT

echo -e "${GREEN}=== Real-time Stream Monitor ===${NC}"
echo -e "Refreshing every ${REFRESH_INTERVAL} seconds"
echo -e "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo -e "${GREEN}=== Stream Status [$(date '+%H:%M:%S')] ===${NC}"
    echo ""
    
    # Get stream data
    STREAMS=$(curl -s -u $AUTH "$API_URL/streams" 2>/dev/null)
    
    if [ -z "$STREAMS" ] || [ "$STREAMS" = "null" ]; then
        echo -e "${RED}❌ Unable to fetch stream data${NC}"
        sleep $REFRESH_INTERVAL
        continue
    fi
    
    # Show each stream
    echo "$STREAMS" | jq -r '.[] | 
        "📺 \(.name)\n" +
        "   Status: \(.status | if . == "running" then "🟢 Running" elif . == "stopped" then "🔴 Stopped" else "🟡 \(.)" end)\n" +
        "   Viewers: \(.stats.viewers // 0)\n" +
        "   Bitrate: \(.stats.bitrate // 0) Kbps\n" +
        "   Uptime: \(.stats.uptime // "N/A")\n" +
        "   ID: \(.id)\n" +
        "---"'
    
    # Show bandwidth
    echo ""
    STATS=$(curl -s -u $AUTH "$API_URL/stats" 2>/dev/null)
    IN=$(echo $STATS | jq -r '.network.in // 0')
    OUT=$(echo $STATS | jq -r '.network.out // 0')
    
    echo -e "📊 Bandwidth:"
    echo -e "   In:  ${YELLOW}${IN} Mbps${NC}"
    echo -e "   Out: ${YELLOW}${OUT} Mbps${NC}"
    
    # Show system resources
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM=$(free -m | awk 'NR==2 {printf "%.1f%%", $3*100/$2}')
    
    echo -e "💻 System:"
    echo -e "   CPU:  ${YELLOW}${CPU}%${NC}"
    echo -e "   RAM:  ${YELLOW}${MEM}${NC}"
    
    sleep $REFRESH_INTERVAL
done