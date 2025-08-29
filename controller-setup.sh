#!/bin/bash

# Jenkins Controller Setup Script
# Ubuntu 22.04 LTS on AWS EC2

set -e

echo "=== Jenkins Controller Setup ==="

# Update system packages
echo "Updating system packages..."
sudo apt update -y

# Install Java OpenJDK 17
echo "Installing Java OpenJDK 17..."
sudo apt install -y openjdk-17-jdk

# Verify Java installation
echo "Java version:"
java -version

# Add Jenkins repository
echo "Adding Jenkins repository..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update package list
sudo apt update -y

# Install Jenkins
echo "Installing Jenkins..."
sudo apt install -y jenkins

# Enable and start Jenkins service
echo "Enabling and starting Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check Jenkins status
sudo systemctl status jenkins --no-pager

# Configure firewall (if UFW is enabled)
if sudo ufw status | grep -q "Status: active"; then
    echo "Configuring UFW firewall..."
    sudo ufw allow 8080
    sudo ufw allow ssh
fi

# Display initial admin password
echo "=== Jenkins Initial Setup ==="
echo "Jenkins is starting up. Please wait a moment..."
sleep 30

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "Initial Admin Password:"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Initial password file not found. Jenkins may still be starting up."
    echo "Run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

# Generate SSH key pair for agent connections
echo "=== Generating SSH Keys for Agent Connections ==="
sudo -u jenkins mkdir -p /var/lib/jenkins/.ssh
sudo -u jenkins ssh-keygen -t ed25519 -f /var/lib/jenkins/.ssh/jenkins_agent_key -N ""

echo "=== Setup Complete ==="
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Use the initial admin password displayed above for first-time setup."
echo ""
echo "SSH Public Key for Agents:"
sudo cat /var/lib/jenkins/.ssh/jenkins_agent_key.pub