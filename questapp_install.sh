#!/bin/bash

# Update system and install Node.js
sudo apt update -y
sudo apt install -y nodejs npm

# Set permissions for the app
sudo chown -R ubuntu:ubuntu /home/ubuntu/app
sudo chmod +x /home/ubuntu/app/bin/*

# Navigate to app directory and install dependencies
cd /home/ubuntu/app && npm install

# Start the app in the background
nohup npm start > /home/ubuntu/deploy.log 2>&1 &