#!/bin/bash

# Assumptions
# - PXE_4640 is running on the host machine
# - PXE_4640 has the user: admin, accessible using the acit_admin_id_rsa SSH key
# - VBoxManage can be run from "/mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe"

# VM Root password is: Password

VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"
NAT_NET_NAME="net_4640"

vboxmanage () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

clean_up() {
    rm -f ./errors.log
    date > errors.log
}

create_network() {
    echo "[+] Removing NAT network ${NAT_NET_NAME}"
    # vboxmanage controlvm "${PXE_NAME}" poweroff 1> /dev/null 2>> errors.log
    vboxmanage natnetwork remove --netname "${NAT_NET_NAME}" 1> /dev/null 2>> errors.log
    
    
    echo "[+] Creating NAT network ${NAT_NET_NAME}"
    vboxmanage natnetwork add --netname "${NAT_NET_NAME}" --network "192.168.250.0/24" --dhcp off --enable \
        --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
        --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
        --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
        --port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22" 1> /dev/null 2>> errors.log
}

create_vm () {
    echo "[+] Removing VM ${VM_NAME}"
    vboxmanage unregistervm "${VM_NAME}" --delete 1> /dev/null 2>> errors.log

    echo "[+] Creating VM ${VM_NAME}"
    vboxmanage createvm \
        --name "${VM_NAME}" \
        --ostype RedHat_64 \
        --register 1> /dev/null 2>> errors.log

    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_PATH=$(vboxmanage showvminfo "${VM_NAME}" | sed -ne "${SED_PROGRAM}")
    BASE_FOLDER=$(dirname "${VBOX_PATH}")

    vboxmanage createmedium disk \
        --filename "${BASE_FOLDER}/VM_ACIT4640.vdi" \
        --size 10000 \
        --format VDI 1> /dev/null 2>> errors.log
    vboxmanage storagectl "${VM_NAME}" \
        --name "IDE" \
        --add ide \
        --controller PIIX4 \
        --portcount 2 \
        --bootable on
    vboxmanage storagectl "${VM_NAME}" \
        --name "SATA" \
        --add sata \
        --controller IntelAhci \
        --portcount 1 \
        --bootable on
    vboxmanage storageattach "${VM_NAME}" \
        --storagectl "SATA" \
        --type hdd \
        --port 0 \
        --device 0 \
        --medium "${BASE_FOLDER}/VM_ACIT4640.vdi" 1> /dev/null 2>> errors.log
    vboxmanage modifyvm "${VM_NAME}" \
        --cpus 1 \
        --memory 2048 \
        --boot1 net \
        --audio none \
        --nic1 natnetwork \
        --cableconnected1 on \
        --nat-network1 "${NAT_NET_NAME}"  
}

configure_pxe() {
    # echo "[+] Adding ${PXE_NAME} to NAT network ${NAT_NET_NAME}"
    # vboxmanage modifyvm "${PXE_NAME}" \
    #    --nic1 natnetwork \
    #    --cableconnected1 on \
    #    --nat-network1 "${NAT_NET_NAME}"  

    # echo "[+] Booting ${PXE_NAME}"
    # vboxmanage controlvm "${PXE_NAME}" poweroff 1> /dev/null 2>> errors.log
    # vboxmanage startvm "${PXE_NAME}" --type headless 1> /dev/null 2>> errors.log

    # cp ./config ~/.ssh/
    # n=0
    # until [ $n -ge 25 ]
    # do
    #     scp ./errors.log admin@pxe:~/ && break 1> /dev/null 2>> errors.log
    #     n=$[$n+1]
    #     sleep 2
    # done

    echo "[+] Copying files to ${PXE_NAME}"
    scp ./ks.cfg admin@pxe:~/ 1> /dev/null 2>> errors.log
    
    # Somehow copy the ks.cfg files into the /var/www/lighttpd/ folder !??
    # scp ./ks.cfg root@pxe:/var/www/lighttpd/ 1> /dev/null 2>> errors.log
}

boot_vm() {
    vboxmanage startvm "${VM_NAME}" --type headless

    # Change from PXE boot to disk boot

    # Restart vm
}

#copy_files() {
    # Copy files from working folder to VM
#}

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

clean_up
create_network
create_vm
configure_pxe
boot_vm
# copy_files
# create_users
# configure_security
# install_packages
# setup_application

# vboxmanage storageattach "${VM_NAME}" \
#        --storagectl "IDE" \
#        --type dvddrive \
#        --port 1 \
#        --device 1 \
#        --medium "${ISO_PATH}"