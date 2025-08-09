#!/bin/bash
set -euo pipefail

# === Logging ===
exec > >(tee /var/log/bootstrap.log | logger -t bootstrap -s 2>/dev/console) 2>&1

echo "🚀 Starting bootstrap process..."

# === Section 1: Base Package Installation ===
echo "📦 Updating system and installing base packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl unzip jq gnupg2 software-properties-common lsb-release apt-transport-https wget

# === Section 2: Install AWS CLI v2 Based on Architecture ===
echo "🌐 Installing AWS CLI v2..."

ARCH=$(uname -m)
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

if [[ "$ARCH" == "x86_64" ]]; then
    curl -s -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
elif [[ "$ARCH" == "aarch64" ]]; then
    curl -s -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

unzip -q awscliv2.zip
sudo ./aws/install --update
cd - && rm -rf "$TMP_DIR"

# === Section 3: Install OpenJDK 17 and set as default ===
echo "☕ Installing OpenJDK 17..."
sudo apt install -y openjdk-17-jdk

echo "🛠️ Setting Java 17 as default..."
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 1710
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac 1710
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac

java -version

# === Section 4: Collect Metadata Securely Using IMDSv2 ===
echo "🔍 Retrieving EC2 metadata..."

IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id)

REGION=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
    http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

echo "✅ Instance ID: $INSTANCE_ID"
echo "✅ Region: $REGION"

# === Section 5: Retrieve EC2 Name Tag and Set Hostname ===
echo "🖥️  Attempting to retrieve instance Name tag from AWS..."

INSTANCE_NAME=$(aws ec2 describe-tags \
    --region "$REGION" \
    --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
    --query "Tags[0].Value" --output text 2>/dev/null || echo "")

if [[ -n "$INSTANCE_NAME" && "$INSTANCE_NAME" != "None" ]]; then
    echo "✅ Setting hostname to EC2 tag: $INSTANCE_NAME"
    sudo hostnamectl set-hostname "$INSTANCE_NAME"
else
    echo "⚠️ Instance Name tag not found or AWS CLI credentials missing. Skipping hostname set."
fi

# === Section 6: Install and Configure Docker ===
echo "🐳 Installing Docker..."

sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# === Section 6.1: Create systemd service for SonarQube ===
echo "🧩 Creating systemd service for SonarQube..."

cat <<EOF | sudo tee /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube Container
Requires=docker.service
After=docker.service
StartLimitIntervalSec=0

[Service]
Restart=always
# Wait until Docker socket is responsive
ExecStartPre=/bin/bash -c 'until docker info >/dev/null 2>&1; do echo "⏳  Waiting for Docker to be ready..."; sleep 2; done'
# Create container if it doesn't exist
ExecStartPre=/bin/bash -c 'docker ps -a --format "{{.Names}}" | grep -w sonar || docker create --name sonar -p 9000:9000 sonarqube:lts-community'
# Start container and attach logs
ExecStart=/usr/bin/docker start -a sonar
ExecStop=/usr/bin/docker stop sonar

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# === Section 7: Install Jenkins ===
echo "🧰 Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | \
    sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update && sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# === Section 8: Install Trivy for Image Scanning ===
echo "🔍 Installing Trivy..."

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update && sudo apt install -y trivy

# === Section 9: Add Jenkins to Docker Group ===
echo "🔑 Adding Jenkins user to Docker group..."
sudo usermod -aG docker jenkins

# === Section 10: Final Steps ===
echo "✅ Bootstrap completed successfully."

echo "♻️ Rebooting to finalize setup..."
sudo reboot

