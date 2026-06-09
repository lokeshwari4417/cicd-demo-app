#!/bin/bash
# ============================================================
#  scripts/setup-ec2.sh
#  Run this ONCE on a fresh AWS EC2 Ubuntu instance to
#  install Docker and prepare the server for deployments.
#
#  Usage:
#    chmod +x setup-ec2.sh
#    sudo ./setup-ec2.sh
# ============================================================

set -e   # Exit on any error
set -u   # Treat undefined variables as errors

echo "========================================"
echo " EC2 Server Setup Script"
echo " $(date)"
echo "========================================"

# ---- Update system packages ----
echo ""
echo "[Step 1/6] Updating system packages..."
apt-get update -y
apt-get upgrade -y

# ---- Install required tools ----
echo ""
echo "[Step 2/6] Installing required tools..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    ca-certificates \
    gnupg \
    lsb-release

# ---- Install Docker ----
echo ""
echo "[Step 3/6] Installing Docker..."

# Remove old versions if any
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# ---- Configure Docker permissions ----
echo ""
echo "[Step 4/6] Configuring Docker permissions..."

# Add ubuntu user to docker group (allows running docker without sudo)
usermod -aG docker ubuntu

echo "Docker version: $(docker --version)"

# ---- Configure Firewall (UFW) ----
echo ""
echo "[Step 5/6] Configuring firewall..."

ufw --force enable
ufw allow OpenSSH         # SSH port 22
ufw allow 3000/tcp        # Application port
ufw allow 80/tcp          # HTTP (optional, for nginx)
ufw allow 443/tcp         # HTTPS (optional)

echo "Firewall status:"
ufw status

# ---- Create app directories ----
echo ""
echo "[Step 6/6] Creating application directories..."

mkdir -p /opt/cicd-app/logs
mkdir -p /opt/cicd-app/scripts
chown -R ubuntu:ubuntu /opt/cicd-app

# ---- Setup log rotation ----
cat > /etc/logrotate.d/cicd-app << 'EOF'
/opt/cicd-app/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF

echo ""
echo "========================================"
echo " Setup Complete!"
echo ""
echo " IMPORTANT: Log out and back in for"
echo " Docker group changes to take effect."
echo ""
echo " Docker: $(docker --version)"
echo "========================================"
