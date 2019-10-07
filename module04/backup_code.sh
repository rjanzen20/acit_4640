# --- Configure PXE
    # vboxmanage controlvm "${PXE_NAME}" poweroff 1> /dev/null 2>> errors.log

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


    # vboxmanage storageattach "${VM_NAME}" \
#        --storagectl "IDE" \
#        --type dvddrive \
#        --port 1 \
#        --device 1 \
#        --medium "${ISO_PATH}"