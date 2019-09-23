#!/bin/bash

# Perform manually
# nmtui
# - Set IP address to 192.168.250.10
# - Set Gateway to 192.168.250.1
# - Set DNS to 8.8.8.8

# ssh root@vm from WSL
# sftp root@vm
# - put /mnt/c/Users/rober/Documents/acit_4640/module03/app_setup.sh
# - put /mnt/c/Users/rober/Documents/acit_4640/module03/acit_admin_id_rsa.pub
# - put /mnt/c/Users/rober/Documents/acit_4640/module03/database.js
# - put /mnt/c/Users/rober/Documents/acit_4640/module03/nginx.conf
# - put /mnt/c/Users/rober/Documents/acit_4640/module03/todoapp.service

ENCRYPTED_PASSWORD="\$6\$kh3u.1TYYVhYgzmD\$ZzVSt6kHRmMjfb9vjyahT8P8hxCdq7hkChgnqMub8W4apZhG/lKch9KUR9S3Vmtq4SYFKlCc6WwrxErqV8Opa1"

create_users () {
    echo "[+] Creating users"
    adduser admin
    echo "admin:${ENCRYPTED_PASSWORD}" | chpasswd -e 1> /dev/null
    usermod -aG wheel admin 1> /dev/null
    useradd -m -r todo-app
    echo "todo-app:${ENCRYPTED_PASSWORD}" | chpasswd -e 1> /dev/null
}

configure_security() {
    echo "[+] Configuring passwordless sudo for wheel group"
    sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

    echo "[+] Creating firewall rules"
    firewall-cmd --zone=public --add-port=80/tcp 1> /dev/null
    firewall-cmd --zone=public --add-port=20/tcp 1> /dev/null
    firewall-cmd --zone=public --add-port=443/tcp 1> /dev/null
    firewall-cmd --runtime-to-permanent 1> /dev/null

    echo "[+] Disabling SELinux"
    setenforce 0
    sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

    echo "[+] Adding public key file to admin .ssh folder"
    mkdir /home/admin/.ssh
    chown -R admin:admin /home/admin/.ssh/
    cp -f /root/acit_admin_id_rsa.pub /home/admin/.ssh/ 1> /dev/null
    chown admin:admin /home/admin/.ssh/acit_admin_id_rsa.pub
}

install_packages() {
    echo "[+] Installing system packages"
    yum -y install epel-release vim git tcpdump curl net-tools bzip2 1> /dev/null 2>> errors.log
    yum -y update 1> /dev/null 2>> errors.log

    echo "[+] Installing application software"
    yum -y install nodejs npm mongodb-server nginx 1> /dev/null 2>> errors.log
}

setup_application() {
    echo "[+] Downloading application files"
    cd /home/todo-app/
    mkdir app
    git clone -q https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/
    chown -R todo-app:todo-app /home/todo-app/app
    chmod 755 /home/todo-app/

    echo "[+] Installing Node packages"
    npm install --prefix /home/todo-app/app/ 1> /dev/null

    echo "[+] Configuring MongoDB"
    cp -f /root/database.js /home/todo-app/app/config/database.js 1> /dev/null
    systemctl enable mongod 1> /dev/null
    systemctl start mongod 1> /dev/null

    echo "[+] Configuring NGINX"
    cp -f /root/nginx.conf /etc/nginx/nginx.conf 1> /dev/null
    systemctl enable nginx 1> /dev/null
    systemctl start nginx 1> /dev/null

    echo "[+] Configuring NodeJS daemon service"
    cp -f /root/todoapp.service /lib/systemd/system/todoapp.service 1> /dev/null
    systemctl daemon-reload 1> /dev/null
    systemctl enable todoapp 1> /dev/null
    systemctl start todoapp 1> /dev/null

    echo "[+] Server started at http://localhost:50080/"
}

create_users
configure_security
install_packages
setup_application