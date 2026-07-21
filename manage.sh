#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="http://localhost:8080/api/v1"
AUTH="admin:ChangeMe123!"

# Function to get VPS IP
get_ip() {
    curl -s ifconfig.me || echo "localhost"
}

# Function to display header
header() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}   Restream Server Manager       ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Server IP: $(get_ip)"
    echo -e "Web UI: http://$(get_ip):8080"
    echo ""
}

# Function to list all streams
list_streams() {
    echo -e "${GREEN}📺 Active Streams:${NC}"
    echo "----------------------------------------"
    curl -s -u $AUTH "$API_URL/streams" 2>/dev/null | jq -r '.[] | "ID: \(.id)\nName: \(.name)\nStatus: \(.status)\nViewers: \(.stats.viewers // 0)\n----------------------------------------"'
}

# Function to show bandwidth
show_bandwidth() {
    echo -e "${GREEN}📊 Bandwidth Usage:${NC}"
    echo "----------------------------------------"
    STATS=$(curl -s -u $AUTH "$API_URL/stats" 2>/dev/null)
    IN=$(echo $STATS | jq -r '.network.in // 0')
    OUT=$(echo $STATS | jq -r '.network.out // 0')
    TOTAL=$(echo "scale=2; $IN + $OUT" | bc)
    
    echo -e "📥 Incoming: ${YELLOW}${IN} Mbps${NC}"
    echo -e "📤 Outgoing: ${YELLOW}${OUT} Mbps${NC}"
    echo -e "📊 Total:    ${YELLOW}${TOTAL} Mbps${NC}"
}

# Function to show outputs
list_outputs() {
    echo -e "${GREEN}🎯 Output Destinations:${NC}"
    echo "----------------------------------------"
    curl -s -u $AUTH "$API_URL/outputs" 2>/dev/null | jq -r '.[] | "Platform: \(.name)\nStatus: \(.status)\nBitrate: \(.bitrate // 0) Kbps\n----------------------------------------"'
}

# Function to start a stream
start_stream() {
    STREAM_ID=$1
    if [ -z "$STREAM_ID" ]; then
        echo -e "${RED}Error: Please provide stream ID${NC}"
        echo "Usage: $0 start STREAM_ID"
        return
    fi
    
    echo -e "${YELLOW}Starting stream $STREAM_ID...${NC}"
    RESPONSE=$(curl -s -X POST -u $AUTH "$API_URL/streams/$STREAM_ID/start")
    if echo $RESPONSE | grep -q "success"; then
        echo -e "${GREEN}✅ Stream started successfully${NC}"
    else
        echo -e "${RED}❌ Failed to start stream${NC}"
        echo $RESPONSE | jq '.'
    fi
}

# Function to stop a stream
stop_stream() {
    STREAM_ID=$1
    if [ -z "$STREAM_ID" ]; then
        echo -e "${RED}Error: Please provide stream ID${NC}"
        echo "Usage: $0 stop STREAM_ID"
        return
    fi
    
    echo -e "${YELLOW}Stopping stream $STREAM_ID...${NC}"
    RESPONSE=$(curl -s -X POST -u $AUTH "$API_URL/streams/$STREAM_ID/stop")
    if echo $RESPONSE | grep -q "success"; then
        echo -e "${GREEN}✅ Stream stopped successfully${NC}"
    else
        echo -e "${RED}❌ Failed to stop stream${NC}"
        echo $RESPONSE | jq '.'
    fi
}

# Function to show logs
show_logs() {
    echo -e "${GREEN}📋 Recent Logs:${NC}"
    echo "----------------------------------------"
    docker logs --tail 50 restreamer
}

# Function to restart services
restart_services() {
    echo -e "${YELLOW}Restarting services...${NC}"
    docker-compose restart
    echo -e "${GREEN}✅ Services restarted${NC}"
}

# Function to update
update_services() {
    echo -e "${YELLOW}Updating services...${NC}"
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}✅ Services updated${NC}"
}

# Function to show stream key
show_stream_key() {
    echo -e "${GREEN}🔑 Stream Key:${NC}"
    echo "----------------------------------------"
    KEY=$(openssl rand -hex 16)
    echo -e "RTMP Ingest URL: rtmp://$(get_ip):1935/live/${KEY}"
    echo -e "RTMPS Ingest URL: rtmps://$(get_ip):443/live/${KEY}"
}

# Main menu
main_menu() {
    header
    echo -e "${GREEN}Available Commands:${NC}"
    echo "  ${BLUE}1${NC}. List all streams"
    echo "  ${BLUE}2${NC}. Show bandwidth usage"
    echo "  ${BLUE}3${NC}. Show output destinations"
    echo "  ${BLUE}4${NC}. Start a stream"
    echo "  ${BLUE}5${NC}. Stop a stream"
    echo "  ${BLUE}6${NC}. Show logs"
    echo "  ${BLUE}7${NC}. Restart services"
    echo "  ${BLUE}8${NC}. Update services"
    echo "  ${BLUE}9${NC}. Show stream key"
    echo "  ${BLUE}0${NC}. Exit"
    echo ""
    read -p "Enter choice (0-9): " choice
    
    case $choice in
        1) list_streams ;;
        2) show_bandwidth ;;
        3) list_outputs ;;
        4) read -p "Enter Stream ID: " id; start_stream $id ;;
        5) read -p "Enter Stream ID: " id; stop_stream $id ;;
        6) show_logs ;;
        7) restart_services ;;
        8) update_services ;;
        9) show_stream_key ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}"; sleep 2; main_menu ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    main_menu
}

# CLI mode
if [ $# -gt 0 ]; then
    case $1 in
        list) list_streams ;;
        bandwidth) show_bandwidth ;;
        outputs) list_outputs ;;
        start) start_stream $2 ;;
        stop) stop_stream $2 ;;
        logs) show_logs ;;
        restart) restart_services ;;
        update) update_services ;;
        key) show_stream_key ;;
        *) echo "Usage: $0 {list|bandwidth|outputs|start|stop|logs|restart|update|key}" ;;
    esac
else
    main_menu
fi