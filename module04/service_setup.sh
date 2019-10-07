#!/bin/bash
# Robert Janzen A01029341

VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"
NAT_NET_NAME="net_4640"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

vboxmanage () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

clean_up() {
    cp ./acit_admin_id_rsa ~/.ssh/
    cp ./config ~/.ssh/
    rm -f ./errors.log
    date > errors.log
}

create_network() {
    echo -e "${GREEN}[+] Removing NAT network ${NAT_NET_NAME}${NC}"
    vboxmanage natnetwork remove --netname "${NAT_NET_NAME}" 1> /dev/null 2>> errors.log
    
    
    echo -e "${GREEN}[+] Creating NAT network ${NAT_NET_NAME}${NC}"
    vboxmanage natnetwork add --netname "${NAT_NET_NAME}" --network "192.168.250.0/24" --dhcp off --enable \
        --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
        --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
        --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
        --port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22" 1> /dev/null 2>> errors.log
}

create_vm () {
    echo -e "${GREEN}[+] Removing VM ${VM_NAME}${NC}"
    vboxmanage controlvm "${VM_NAME}" poweroff 1> /dev/null 2>> errors.log
    vboxmanage unregistervm "${VM_NAME}" --delete 1> /dev/null 2>> errors.log

    echo -e "${GREEN}[+] Creating VM ${VM_NAME}${NC}"
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
        --boot1 disk \
        --boot2 net \
        --audio none \
        --nic1 natnetwork \
        --cableconnected1 on \
        --nat-network1 "${NAT_NET_NAME}"  
}

configure_pxe() {
    echo -e "${GREEN}[+] Connecting ${PXE_NAME} to ${NAT_NET_NAME}${NC}"
    vboxmanage controlvm "${PXE_NAME}" poweroff 1> /dev/null 2>> errors.log
    vboxmanage modifyvm "${PXE_NAME}" \
       --nic1 natnetwork \
       --cableconnected1 on \
       --nat-network1 "${NAT_NET_NAME}"

    echo -e "${GREEN}[+] Starting ${PXE_NAME}${NC}"
    vboxmanage startvm "${PXE_NAME}" --type headless 1> /dev/null 2>> errors.log
    while /bin/true; do
        ssh -p 50222 -o ConnectTimeout=2 -q pxe exit 1> /dev/null 2>> errors.log
        if [ $? -ne 0 ]; then
                echo -e "${RED}[-] ${PXE_NAME} is not up, sleeping...${NC}"
                sleep 2
        else
                break
        fi
    done

    echo -e "${GREEN}[+] Copying files to ${PXE_NAME}${NC}"
    scp ./ks.cfg admin@pxe:~/ 1> /dev/null 2>> errors.log
    scp ./app_setup.sh admin@pxe:~/ 1> /dev/null 2>> errors.log
    scp -r ./files/ admin@pxe:~/ 1> /dev/null 2>> errors.log
    ssh admin@pxe "sudo mv ~/ks.cfg /var/www/lighttpd/" 1> /dev/null 2>> errors.log
    ssh admin@pxe "sudo mv ~/app_setup.sh /var/www/lighttpd/" 1> /dev/null 2>> errors.log
    ssh admin@pxe "sudo rm -r -f /var/www/lighttpd/files/" 1> /dev/null 2>> errors.log
    ssh admin@pxe "sudo mv ~/files/ /var/www/lighttpd/" 1> /dev/null 2>> errors.log
}

boot_vm() {
    echo -e "${GREEN}[+] Starting ${VM_NAME}${NC}"
    vboxmanage startvm "${VM_NAME}" --type headless 1> /dev/null 2>> errors.log
}

clean_up
create_network
create_vm
configure_pxe
boot_vm