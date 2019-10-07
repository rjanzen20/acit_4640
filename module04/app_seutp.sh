#!/bin/bash
# Place files in /var/www/lighttpd

ENCRYPTED_PASSWORD="\$6\$kh3u.1TYYVhYgzmD\$ZzVSt6kHRmMjfb9vjyahT8P8hxCdq7hkChgnqMub8W4apZhG/lKch9KUR9S3Vmtq4SYFKlCc6WwrxErqV8Opa1"
VM_NAME="VM_ACIT4640"
GREEN="\033[0;32m"
NC="\033[0m"

create_users () {
    echo -e "${GREEN}[+] Creating users${NC}"
    adduser admin
    echo "admin:${ENCRYPTED_PASSWORD}" | chpasswd -e 1> /dev/null
    usermod -aG wheel admin 1> /dev/null
    useradd -m -r todo-app
    echo "todo-app:${ENCRYPTED_PASSWORD}" | chpasswd -e 1> /dev/null
}

configure_security() {
    echo -e "${GREEN}[+] Configuring passwordless sudo for wheel group${NC}"
    sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

    echo -e "${GREEN}[+] Creating firewall rules"
    firewall-cmd --zone=public --add-port=80/tcp 1> /dev/null
    firewall-cmd --zone=public --add-port=20/tcp 1> /dev/null
    firewall-cmd --zone=public --add-port=443/tcp 1> /dev/null
    firewall-cmd --runtime-to-permanent 1> /dev/null

    echo -e "${GREEN}[+] Disabling SELinux${NC}"
    setenforce 0
    sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

    echo -e "${GREEN}[+] Adding public key file to admin .ssh folder${NC}"
    mkdir /home/admin/.ssh
    chown -R admin:admin /home/admin/.ssh/
    cp -f /root/acit_admin_id_rsa.pub /home/admin/.ssh/ 1> /dev/null
    chown admin:admin /home/admin/.ssh/acit_admin_id_rsa.pub
}

install_packages() {
    echo -e "${GREEN}[+] Installing system packages${NC}"
    yum -y install epel-release vim git tcpdump curl net-tools bzip2 1> /dev/null 2>> errors.log
    yum -y update 1> /dev/null 2>> errors.log

    echo -e "${GREEN}[+] Installing application software${NC}"
    yum -y install nodejs npm mongodb-server nginx 1> /dev/null 2>> errors.log
}

setup_application() {
    echo -e "${GREEN}[+] Downloading application files${NC}"
    cd /home/todo-app/
    mkdir app
    git clone -q https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/
    chown -R todo-app:todo-app /home/todo-app/app
    chmod 755 /home/todo-app/

    echo -e "${GREEN}[+] Installing Node packages${NC}"
    npm install --prefix /home/todo-app/app/ 1> /dev/null

    echo -e "${GREEN}[+] Configuring MongoDB${NC}"
    cp -f /root/database.js /home/todo-app/app/config/database.js 1> /dev/null
    systemctl enable mongod 1> /dev/null
    systemctl start mongod 1> /dev/null

    echo -e "${GREEN}[+] Configuring NGINX${NC}"
    cp -f /root/nginx.conf /etc/nginx/nginx.conf 1> /dev/null
    systemctl enable nginx 1> /dev/null
    systemctl start nginx 1> /dev/null

    echo -e "${GREEN}[+] Configuring NodeJS daemon service${NC}"
    cp -f /root/todoapp.service /lib/systemd/system/todoapp.service 1> /dev/null
    systemctl daemon-reload 1> /dev/null
    systemctl enable todoapp 1> /dev/null
    systemctl start todoapp 1> /dev/null

    echo -e "${GREEN}[+] Server started at http://localhost:50080/${NC}"
}

create_users
configure_security
install_packages
setup_application