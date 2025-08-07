#!/bin/bash
set -e

# Error handling and log file redirection:
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

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
sudo apt update && sudo apt upgrade -y curl gnupg2 software-properties-common

# Install Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Install Jenkins
sudo apt install -y openjdk-11-jdk
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Trivy
sudo apt install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install -y trivy

sudo usermod -aG docker jenkins

echo "✔️ Setup complete. Rebooting..."
sudo reboot