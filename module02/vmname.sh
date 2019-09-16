vboxmanage () { VBoxManage.exe "$@"; }
VM_NAME="VM_ACIT4640"
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|g; s|^\(\S\):/|/mnt/\L\1/|p }"
VBOX_FILE=$(vboxmanage showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

echo $VBOX_FILE
echo $VM_DIR