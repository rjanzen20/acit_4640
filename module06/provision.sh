#!/bin/bash
# Robert Janzen A01029341

ENCRYPTED_PASSWORD="\$6\$kh3u.1TYYVhYgzmD\$ZzVSt6kHRmMjfb9vjyahT8P8hxCdq7hkChgnqMub8W4apZhG/lKch9KUR9S3Vmtq4SYFKlCc6WwrxErqV8Opa1"

create_user () {
    useradd -m -r todo-app
    echo "todo-app:${ENCRYPTED_PASSWORD}" | chpasswd -e
}

configure_security() {
    sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

    firewall-cmd --zone=public --add-port=80/tcp
    firewall-cmd --zone=public --add-port=20/tcp
    firewall-cmd --zone=public --add-port=443/tcp
    firewall-cmd --runtime-to-permanent

    setenforce 0
    sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
}

clone_repo () {
    cd /home/todo-app/
    mkdir app
    git clone -q https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/
    chown -R todo-app:todo-app /home/todo-app/app
    chmod 755 /home/todo-app/
}

setup_application() {
    npm install --prefix /home/todo-app/app/ 

    cp -f /home/admin/database.js /home/todo-app/app/config/database.js
    systemctl enable mongod
    systemctl start mongod

    cp -f /home/admin/nginx.conf /etc/nginx/nginx.conf
    systemctl enable nginx
    systemctl start nginx

    cp -f /home/admin/todoapp.service /lib/systemd/system/todoapp.service
    systemctl daemon-reload
    systemctl enable todoapp
    systemctl start todoapp
}

create_user
configure_security
clone_repo
setup_application