#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }

VM_NAME="VM_ACIT4640"
ISO_PATH="C:\\Users\\rober\\VirtualBox VMs\\CentOS-7-x86_64-Minimal-1810.iso"
NAT_NET_NAME="net_4640"

setup_system () {
    echo "Configuring system."

    vboxmanage createvm \
        --name "${VM_NAME}" \
        --ostype RedHat_64 \
        --register

    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_PATH=$(vboxmanage showvminfo "${VM_NAME}" | sed -ne "${SED_PROGRAM}")
    BASE_FOLDER=$(dirname "${VBOX_PATH}")

    vboxmanage createmedium disk \
        --filename "${BASE_FOLDER}/VM_ACIT4640.vdi" \
        --size 10000 \
        --format VDI

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
        --medium "${BASE_FOLDER}/VM_ACIT4640.vdi"
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