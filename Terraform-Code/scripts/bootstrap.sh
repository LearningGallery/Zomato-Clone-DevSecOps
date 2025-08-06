#!/bin/bash
set -e

# Set hostname to EC2 Name tag (if running in EC2)
if [[ $(uname -a) == *"amzn"* || -f /sys/hypervisor/uuid ]]; then
    echo "💻 Attempting to set hostname from EC2 instance metadata..."
    EC2_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name || true)

    if [[ -n "$EC2_NAME" ]]; then
        echo "🔧 Setting hostname to: $EC2_NAME"
        sudo hostnamectl set-hostname "$EC2_NAME"
    else
        echo "⚠️ Could not retrieve EC2 Name tag from metadata. Skipping hostname set."
    fi
else
    echo "🧪 Not an EC2 instance or metadata unavailable. Skipping hostname set."
fi

# Update
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Install Jenkins
sudo apt install -y openjdk-11-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > \
    /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Trivy
sudo apt install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install -y trivy