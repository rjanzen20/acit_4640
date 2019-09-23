#!/bin/bash

# Perform manually
# nmtui
# - Set IP address to 192.168.250.10/
# - Set Gateway to 192.168.250.1
# - Set DNS to 8.8.8.8
# ssh root@vm from WSL
# Copy script to root home

# Create admin account and add to wheel group
adduser admin
echo "P@ssw0rd" | passwd admin --stdin
usermod -aG wheel admin

# Add SSH key to the admin user authorized keys
# SSH is readable by the admin user only

# Allow passwordless sudo for members of the wheel group
sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

# Install additional packages and update the system
yum install epel-release vim git tcpdump curl net-tools bzip2
yum update

# Firewall configuration ports 22, 80, and 443
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --zone=public --add-port=20/tcp
firewall-cmd --zone=public --add-port=443/tcp
firewall-cmd --runtime-to-permanent

# Disable SELinux
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

# Install VBox Additions
yum install kernel-devel kernel-headers gcc make
mkdir -p /media/cdrom

# Create application user
useradd -m -r todo-app $$ passwd -l todo-app

# Install software
yum install nodejs npm mongodb-server nginx

# Enable and start services
systemctl enable mongod && systemctl start mongod
systemctl enable nginx && systemctl start nginx

# Node application setup
su - todo-app
mkdir app
git clone https://github.com/timoguic/ACIT4640-todo-app.git .
npm install

# Nginx setup
# Replace nginx.conf

# Run server
node server.js

# Test setup
curl -s localhost:8080/api/todos | jq