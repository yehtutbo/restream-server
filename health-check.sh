#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Restream Server Health Check ===${NC}"
echo ""

# Check Docker
echo -n "Docker: "
if docker ps &>/dev/null; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
    exit 1
fi

# Check Restreamer
echo -n "Restreamer: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
fi

# Check RTMP port
echo -n "RTMP (1935): "
if nc -zv localhost 1935 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ Open${NC}"
else
    echo -e "${RED}❌ Closed${NC}"
fi

# Check RTMPS port
echo -n "RTMPS (443): "
if nc -zv localhost 443 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ Open${NC}"
else
    echo -e "${YELLOW}⚠️  Closed (optional)${NC}"
fi

# Check Web UI
echo -n "Web UI (8080): "
if nc -zv localhost 8080 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ Open${NC}"
else
    echo -e "${RED}❌ Closed${NC}"
fi

# Check Prometheus
echo -n "Prometheus (9090): "
if nc -zv localhost 9090 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ Open${NC}"
else
    echo -e "${YELLOW}⚠️  Not running (optional)${NC}"
fi

# Check Grafana
echo -n "Grafana (3000): "
if nc -zv localhost 3000 2>&1 | grep -q "succeeded"; then
    echo -e "${GREEN}✅ Open${NC}"
else
    echo -e "${YELLOW}⚠️  Not running (optional)${NC}"
fi

# Check disk space
echo -n "Disk Space: "
USED=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $USED -lt 80 ]; then
    echo -e "${GREEN}✅ ${USED}% used${NC}"
else
    echo -e "${YELLOW}⚠️  ${USED}% used (consider cleaning)${NC}"
fi

# Check memory usage
echo -n "Memory Usage: "
MEM=$(free -m | awk 'NR==2 {printf "%.1f%%", $3*100/$2}')
echo -e "${GREEN}${MEM}${NC}"

# Check active streams
echo -n "Active Streams: "
COUNT=$(curl -s -u admin:ChangeMe123! http://localhost:8080/api/v1/streams 2>/dev/null | jq '.[] | select(.status=="running")' | wc -l)
echo -e "${GREEN}${COUNT}${NC}"

# Check bandwidth
echo ""
echo "Network Statistics:"
IN=$(curl -s -u admin:ChangeMe123! http://localhost:8080/api/v1/stats 2>/dev/null | jq -r '.network.in // 0')
OUT=$(curl -s -u admin:ChangeMe123! http://localhost:8080/api/v1/stats 2>/dev/null | jq -r '.network.out // 0')
echo -e "  📥 In: ${YELLOW}${IN} Mbps${NC}"
echo -e "  📤 Out: ${YELLOW}${OUT} Mbps${NC}"

echo ""
echo -e "${GREEN}=== Health Check Complete ===${NC}"