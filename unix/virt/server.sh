#!/usr/bin/env bash

# Set variables
HOST_DIR="machines"
VM_NAME="proxmox"
VM_DIR="$HOME/machines/vm"
IMAGE_DIR="$HOME/machines/images"
SOCKET_DIR="$VM_DIR"
#ISO_FILE="$IMAGE_DIR/proxmox-ve_8.3-1.iso"
ISO_FILE=$(find "$IMAGE_DIR" -type f -iname "proxmox*.iso" -exec stat --format="%Y %n" {} \; | sort -n | tail -n 1 | cut -d' ' -f2-)
QCOW2_FILE="$VM_DIR/$VM_NAME.qcow2"
HOST_PORT=22220
GUEST_PORT=22
SHARED_DIR="$HOME/machines/shared"
FIRMWARE_DIR="$HOME/machines/firmware"
VM_SIZE="300G" # Disk size in GB
VM_RAM="12G"   # RAM size
VM_CPU="6"     # Number of virtual CPUs
CORES=$((VM_CPU / 2))
THREADS_PER_CORE=2
SOCKETS=1

# Set SMP configuration
SMP_CONFIG="cores=$CORES,threads=$THREADS_PER_CORE,sockets=$SOCKETS"

# Ensure necessary directories exist
mkdir -p "$HOME"/"$HOST_DIR"
mkdir -p "$VM_DIR" "$IMAGE_DIR" "$SHARED_DIR" "$FIRMWARE_DIR"

# Locate OVMF firmware files
OVMF_DIRS=(
    "/usr/share/OVMF"
    "/usr/share/qemu"
    "/usr/lib/qemu"
    "/usr/share/edk2"
    "/usr/lib/edk2"
)

OVMF_CODE=""
OVMF_VARS=""

for dir in "${OVMF_DIRS[@]}"; do
    [[ -z "$OVMF_CODE" ]] && OVMF_CODE=$(find "$dir" -type f -name "OVMF_CODE.fd" -o -name "edk2-x86_64-code.fd" 2>/dev/null | head -n 1)
    [[ -z "$OVMF_VARS" ]] && OVMF_VARS=$(find "$dir" -type f -name "OVMF_VARS.fd" 2>/dev/null | head -n 1)
    [[ -n "$OVMF_CODE" && -n "$OVMF_VARS" ]] && break
done

# Ensure a writable copy of OVMF_VARS.fd
OVMF_VARS="$FIRMWARE_DIR/OVMF_VARS.fd"

if [[ ! -f "$OVMF_VARS" ]]; then
    echo "Copying OVMF_VARS.fd to $OVMF_VARS"
    cp /usr/share/edk2/OvmfX64/OVMF_VARS.fd "$OVMF_VARS" 2>/dev/null || {
        echo "Error: Failed to copy OVMF_VARS.fd!" >&2
        exit 1
    }
fi

# Check if required files exist
if [[ -z "$OVMF_CODE" ]]; then
    echo "Error: OVMF_CODE.fd not found!" >&2
    exit 1
fi
if [[ ! -f "$OVMF_VARS" ]]; then
    echo "Error: OVMF_VARS.fd not found or could not be copied!" >&2
    exit 1
fi
if [[ ! -f "$ISO_FILE" ]]; then
    echo "Warning: $ISO_FILE ISO not found at $IMAGE_DIR"
fi

# Check if the qcow2 image file exists; if not, create it
if [[ ! -f "$QCOW2_FILE" ]]; then
    echo "Creating $QCOW2_FILE with a size of $VM_SIZE"
    qemu-img create -f qcow2 "$QCOW2_FILE" "$VM_SIZE" || {
        echo "Error: Failed to create qcow2 image!" >&2
        exit 1
    }
else
    echo ""
fi

# Run QEMU
/sbin/qemu-system-x86_64 \
    -name "$VM_NAME",process="$VM_NAME" \
    -machine q35,smm=off,vmport=off,accel=kvm \
    -global kvm-pit.lost_tick_policy=discard \
    -cpu host \
    -smp "$SMP_CONFIG" \
    -m "$VM_RAM" \
    -device virtio-balloon \
    -pidfile "$VM_DIR/$VM_NAME.pid" \
    -rtc base=utc,clock=host \
    -vga none \
    -device virtio-vga-gl,xres=1280,yres=800 \
    -display sdl,gl=on \
    -device virtio-rng-pci,rng=rng0 \
    -object rng-random,id=rng0,filename=/dev/urandom \
    -device qemu-xhci,id=spicepass \
    -chardev spicevmc,id=usbredirchardev1,name=usbredir \
    -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
    -chardev spicevmc,id=usbredirchardev2,name=usbredir \
    -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
    -chardev spicevmc,id=usbredirchardev3,name=usbredir \
    -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3 \
    -device pci-ohci,id=smartpass \
    -device usb-ccid \
    -device usb-ehci,id=input \
    -device usb-kbd,bus=input.0 \
    -k en-us \
    -device usb-tablet,bus=input.0 \
    -audiodev pipewire,id=audio0 \
    -device intel-hda \
    -device hda-micro,audiodev=audio0 \
    -device virtio-net,netdev=nic \
    -netdev user,hostname="$VM_NAME",hostfwd=tcp::"$HOST_PORT"-:"$GUEST_PORT",id=nic \
    -fsdev local,id=fsdev0,path="$SHARED_DIR",security_model=mapped-xattr \
    -device virtio-9p-pci,fsdev=fsdev0,mount_tag="SharedDir" \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file="$OVMF_CODE",readonly=on \
    -drive if=pflash,format=raw,unit=1,file="$OVMF_VARS" \
    -drive media=cdrom,index=0,file="$ISO_FILE" \
    -device virtio-blk-pci,drive=SystemDisk \
    -drive id=SystemDisk,if=none,format=qcow2,file="$QCOW2_FILE" \
    -monitor unix:"$SOCKET_DIR/$VM_NAME-monitor.socket",server,nowait \
    -serial unix:"$SOCKET_DIR/$VM_NAME-serial.socket",server,nowait
#-serial unix:"$SOCKET_DIR/$VM_NAME-serial.socket",server,nowait 2>/dev/null
#-netdev user,hostname="$VM_NAME",hostfwd=tcp::"$HOST_PORT"-:"$GUEST_PORT",smb="$SHARED_DIR",id=nic \
