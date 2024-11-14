#!/bin/bash
# EC2 user data script for Ubuntu to install dependencies, pull Node.js code from GitHub, and run the server

# Update the system
apt-get update -y

# Install necessary dependencies (AWS CLI, git, curl)
apt-get install -y awscli git curl

# Install Node.js (example for version 14.x)
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs

# Clone the Node.js app from GitHub
cd /home/ubuntu
git clone https://github.com/atindraraut/node_backend_template_dummy.git app
cd /home/ubuntu/app

# Install the Node.js app dependencies
npm install

# Create a systemd service file for the Node.js app
cat <<EOL > /etc/systemd/system/my-node-app.service
[Unit]
Description=Node.js Example App
After=network.target

[Service]
ExecStart=/usr/bin/node /home/ubuntu/app/server.js
WorkingDirectory=/home/ubuntu/app
Restart=always
User=ubuntu
Group=ubuntu
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecReload=/bin/kill -HUP \$MAINPID
TimeoutSec=20
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=my-node-app

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable my-node-app.service
systemctl start my-node-app.service
