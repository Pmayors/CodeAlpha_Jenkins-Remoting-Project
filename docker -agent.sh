#!/bin/bash

# Docker Agent Setup - Ubuntu 22.04
set -e

echo "=== Docker Agent Setup ==="

# Update packages
sudo apt update -y

# Install Java 17
sudo apt install -y openjdk-17-jdk

# Create jenkins user
sudo useradd -m -s /bin/bash jenkins
echo "jenkins:admin" | sudo chpasswd
sudo usermod -aG sudo jenkins

# Create directories
sudo -u jenkins mkdir -p /home/jenkins/agent
sudo -u jenkins mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Start Docker and add jenkins to docker group
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins

# Harden SSH
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "Docker Agent Setup Complete"
echo "Add controller SSH key to: /home/jenkins/.ssh/authorized_keys"