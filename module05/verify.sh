#!/bin/bash

# Before runnning
# 1. Manually import ova file
# 2. Manually set IP to 192.168.250.10/24 with nmtui

VM_NAME="4640_BASE"
NAT_NET_NAME="acit4640packer"

vboxmanage () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

clean_up() {
    vboxmanage controlvm "${VM_NAME}" poweroff 1> /dev/null 2>> errors.log
    vboxmanage natnetwork remove --netname "${NAT_NET_NAME}" 1> /dev/null 2>> errors.log
}

create_network() {
    vboxmanage natnetwork add --netname "${NAT_NET_NAME}" --network "192.168.250.0/24" --dhcp off --enable \
        --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"
}

modify_vm() {
    vboxmanage modifyvm "${VM_NAME}" \
        --cpus 1 \
        --memory 2048 \
        --boot1 disk \
        --nic1 natnetwork \
        --cableconnected1 on \
        --nat-network1 "${NAT_NET_NAME}"
}

boot_vm() {
    vboxmanage startvm "${VM_NAME}" --type headless
}

clean_up
create_network
modify_vm
boot_vm