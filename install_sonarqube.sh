#!/bin/bash

# Install SonarQube on Ubuntu 24.04

# Prerequisites
echo "Updating package lists..."
sudo apt update -y

echo "Installing Java..."
sudo apt install openjdk-17-jdk -y  # Or the required Java version

echo "Installing PostgreSQL..."
sudo apt install postgresql postgresql-contrib -y

echo "Creating SonarQube database and user..."
sudo -i -u postgres << EOF
createuser sonar
createdb sonar -O sonar
psql
ALTER USER sonar WITH ENCRYPTED PASSWORD 'your_password';  # Replace with a strong password
\q
EOF
exit

# Installation
echo "Downloading SonarQube (please download manually from https://www.sonarqube.org/downloads/ and place the zip file in /tmp/)"
# The script now requires manual download for the reasons explained previously.
# You will scp it to the server.

if [ ! -f /tmp/sonarqube-*.zip ]; then
    echo "SonarQube ZIP file not found in /tmp/.  Please download it and place it there."
    exit 1
fi

echo "Moving and extracting SonarQube..."
sudo mv /tmp/sonarqube-*.zip /opt
cd /opt
sudo unzip sonarqube-*.zip

# Rename extracted directory (Important)
echo "Creating symbolic link for SonarQube directory..."
SONARQUBE_DIR=$(ls -d /opt/sonarqube-*) # Get the actual directory name
sudo ln -s "$SONARQUBE_DIR" /opt/sonarqube

echo "Creating SonarQube user..."
sudo adduser --system --no-create-home --group --disabled-login sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

echo "Configuring SonarQube..."
sudo nano /opt/sonarqube/conf/sonar.properties << EOF
sonar.jdbc.username=sonar
sonar.jdbc.password=your_password  # Replace with the same password as above
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
EOF


echo "Creating systemd service file..."
sudo nano /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

echo "Starting SonarQube..."
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube

echo "Checking SonarQube status..."
sudo systemctl status sonarqube

echo "Setting file descriptor limits..."
sudo nano -a /etc/security/limits.conf << EOF
sonarqube - nofile 65536
sonarqube - nproc 4096
EOF

echo "Setting virtual memory limit..."
sudo sysctl -w vm.max_map_count=262144

echo "Allowing firewall traffic on port 9000..."
sudo ufw allow 9000
sudo ufw enable

echo "SonarQube installation complete. Access it at http://your_server_ip:9000"