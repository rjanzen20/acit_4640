#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }

VDI_PATH="C:\\Users\\rober\\VirtualBox VMs\\VM_ACIT4640\\VM_ACIT4640.vdi"
ISO_PATH="C:\\Users\\rober\\VirtualBox VMs\\CentOS-7-x86_64-Minimal-1810.iso"
BASE_FOLDER="C:\\Users\\rober\\VirtualBox VMs\\"
VM_NAME="VM_ACIT4640"
NAT_NET_NAME="net_4640"

setup_system () {
    vboxmanage createmedium disk \
        --filename "${VDI_PATH}" \
        --size 10000 \
        --format VDI
    vboxmanage createvm \
        --name "${VM_NAME}" \
        --basefolder "${BASE_FOLDER}" \
        --ostype RedHat_64 \
        --register
    vboxmanage storagectl "${VM_NAME}" \
        --name "IDE" \
        --add ide \
        --controller PIIX4 \
        --portcount 2 \
        --bootable on
    vboxmanage storageattach "${VM_NAME}" \
        --storagectl "IDE" \
        --type dvddrive \
        --port 1 \
        --device 1 \
        --medium "${ISO_PATH}"
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
        --medium "${VDI_PATH}"
    vboxmanage modifyvm "${VM_NAME}" \
        --cpus 1 \
        --memory 1024 \
        --boot1 disk \
        --audio none \
        --nic1 natnetwork \
        --cableconnected1 on \
        --nat-network1 "${NAT_NET_NAME}"  
}

setup_system
echo "VM Setup Complete!"