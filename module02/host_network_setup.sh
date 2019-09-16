#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }

vboxmanage natnetwork add --netname "net_4640" --network "192.168.250.0/24" --dhcp off --enable \
    --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
    --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
    --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"