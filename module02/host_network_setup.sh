#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }

vboxmanage natnetwork --netname net_4640 --network "192.168.250.0/24" --dhcp off --enable
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "SSH ssh:tcp:[]:50022:[192.168.250.10]:22"
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "HTTP http:tcp:[]:50022:[192.168.250.10]:80"
vboxmanage natnetwork modify --netname net_4640 --port-forward-4 "HTTPS https:tcp:[]:50022:[192.168.250.10]:443"

vboxmanage createvm --name "VM_ACIT4640" --basefolder "" --ostype RedHat_64 --register
vboxmanage storagectl --add
vboxmanage storageattach vm
vboxmanage createmedium disk
vboxmanage modifyvm -cpu -memory -boot
