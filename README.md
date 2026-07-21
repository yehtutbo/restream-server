# Restream Server - Self-Hosted RTMP Multi-Streaming

A self-hosted solution for re-streaming RTMP/RTMPS video feeds to multiple social media platforms simultaneously with web UI control, metric monitoring, and automatic failover support.

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh && sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "[https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname](https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname) -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
