#!/bin/bash

# Maven Agent Setup - Ubuntu 22.04
set -e

echo "=== Maven Agent Setup ==="

# Update packages
sudo apt update -y

# Install Java 17 and Maven
sudo apt install -y openjdk-17-jdk maven git

# Create jenkins user
sudo useradd -m -s /bin/bash jenkins
echo "jenkins:admin" | sudo chpasswd
sudo usermod -aG sudo jenkins

# Create directories
sudo -u jenkins mkdir -p /home/jenkins/agent
sudo -u jenkins mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

# Harden SSH
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "Maven Agent Setup Complete"
echo "Java version:" && java -version
echo "Maven version:" && mvn -version
echo "Add controller SSH key to: /home/jenkins/.ssh/authorized_keys"