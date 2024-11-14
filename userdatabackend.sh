#!/bin/bash
# EC2 user data script for Ubuntu to install dependencies, pull Node.js code from GitHub, and run the server

# Update the system
apt-get update -y

# Install necessary dependencies (AWS CLI, git, curl)
apt-get install -y awscli git curl

# Install Node.js (example for version 14.x)
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs
apt-get install -y npm
# Install pm2 globally
npm install pm2@latest -g

# Clone the Node.js app from GitHub
cd /home/ubuntu
git clone https://github.com/atindraraut/node_backend_template_dummy.git app
cd /home/ubuntu/app

# Install the Node.js app dependencies
npm install

# Start the Node.js app with pm2
pm2 start server.js --name "my-node-app"

