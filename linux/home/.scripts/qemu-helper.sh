#!/bin/bash

# Created By: srdusr
# Created On: Wed 02 Aug 2023 16:16:21 PM CAT
# Project: QEMU setup/opener helper wrapper script

# Set global variables for VM parameters
ram_size="4G"

# Function to prompt user for VM parameters
function get_vm_parameters() {
    read -p "Enter VM name (default: vm): " vm_name
    vm_name=${vm_name:-vm}

    # Set the default ISO file path to ~/machines/images
    default_iso_path="$HOME/machines/images"

    # Generate completions for ISO and IMG files in the images directory
    COMPREPLY=()
    local files=$(compgen -G "$default_iso_path/*.{iso,img}" -o plusdirs)
    for file in $files; do
        COMPREPLY+=("$file")
    done

    # Use read with -i and -e options for tab-completion
    read -ep "Enter ISO file path (default: $default_iso_path): " -i "$default_iso_path" iso_path

    # Manually expand the ~ to the user's home directory
    iso_path=$(eval echo "$iso_path")

    # Validate the user input
    while [ ! -f "$iso_path" ]; do
        read -ep "Invalid file path. Enter a valid ISO file path: " iso_path
    done

    # Check if the selected file is an IMG file
    if [[ "$iso_path" == *.img ]]; then
        guest_os="windows"
    else
        guest_os="linux"
    fi

    # Show available disk space before asking for disk image size
    echo "Available disk space:"
    df -h "$vm_images_path"

    read -p "Enter disk image size in GB (default: 10G): " disk_size
    disk_size=${disk_size:-10G}

    read -p "Enter RAM size in GB (default: 4G): " ram_size
    ram_size=${ram_size:-4G}

    # Check if the RAM size is in the correct format (e.g., "4G")
    while ! [[ $ram_size =~ ^[0-9]+[kKmMgGtTpPeE]$ ]]; do
        read -p "Invalid RAM size format. Enter RAM size in GB (e.g., 4G): " ram_size
    done

    read -p "Enter number of CPU cores (default: 2): " cpu_cores
    cpu_cores=${cpu_cores:-2}
}


# Function to list available VMs
function list_vms() {
    echo "Available VMs:"
    for vm_file in "$vm_images_path"/*.qcow2; do
        vm=$(basename "$vm_file" .qcow2)
        echo "  - $vm"
    done
}

# Function to list available ISO and IMG files in the images directory
function list_iso_img_files() {
    echo "Available ISO and IMG files in $iso_images_path:"
    iso_img_files=()
    while IFS= read -r -d $'\0' file; do
        iso_img_files+=("$file")
    done < <(find "$iso_images_path" -type f \( -iname \*.iso -o -iname \*.img \) -print0)

    for ((i = 0; i < ${#iso_img_files[@]}; i++)); do
        echo "  $((i + 1)). ${iso_img_files[i]##*/}"
    done
}

# Function to check if VM is already running
function is_vm_running() {
    vm_name=$1
    if ps aux | grep -v grep | grep -q "[q]emu-system-x86_64.*$vm_name"; then
        return 0
    else
        return 1
    fi
}

# Function to start VM
function start_vm() {
    vm_name=$1
    is_vm_running "$vm_name"
    if [ $? -eq 0 ]; then
        echo "VM '$vm_name' is already running."
        return
    fi

    # VM parameters
    qemu_cmd="qemu-system-x86_64 -enable-kvm -machine type=q35 -m $ram_size -cpu host -smp 2 -vga virtio"
    qemu_cmd+=" -device qemu-xhci -device usb-tablet -device usb-kbd -device virtio-net,netdev=user0 -netdev user,id=user0,hostfwd=tcp::5555-:22"
    qemu_cmd+=" -cdrom \"$iso_path\" -drive file=\"$vm_images_path/$vm_name.qcow2\",index=0,media=disk,if=virtio"
    
    if [[ $guest_os == "windows" ]]; then
        qemu_cmd+=" -drive file=\"$iso_images_path/virtio-win.iso\",index=3,media=cdrom"
    fi
    
    qemu_cmd+=" -boot menu=on"
    qemu_cmd+=" -net nic -net user,hostname=$vm_name -name \"$vm_name\""

    echo "Starting VM: $vm_name"
    eval "$qemu_cmd"
}

# Main script starts here
vm_images_path="$HOME/machines/vm"
iso_images_path="$HOME/machines/images"

# Check if directories exist
mkdir -p "$vm_images_path"
mkdir -p "$iso_images_path"

# List available VMs
list_vms

# List available ISO and IMG files in the images directory
list_iso_img_files

# Ask the user if they want to use an existing VM or create a new one
read -p "Do you want to use an existing VM? (y/n): " use_existing_vm
if [[ $use_existing_vm =~ ^[Yy]$ ]]; then
    read -p "Enter the name of the existing VM: " existing_vm_name
    while [ ! -f "$vm_images_path/$existing_vm_name.qcow2" ]; do
        echo "VM '$existing_vm_name' does not exist."
        read -p "Enter a valid existing VM name: " existing_vm_name
    done
    vm_name=$existing_vm_name
else
    # Prompt user for VM parameters
    get_vm_parameters

    # Check if VM already exists
    if [ -f "$vm_images_path/$vm_name.qcow2" ]; then
        read -p "VM '$vm_name' already exists. Do you want to start it? (y/n): " start_vm_choice
        if [[ $start_vm_choice =~ ^[Yy]$ ]]; then
            start_vm "$vm_name"
            exit 0
        fi
    else
        # Create new VM
        echo "Creating new VM: $vm_name"
        qemu-img create -f qcow2 "$vm_images_path/$vm_name.qcow2" "$disk_size"
        start_vm "$vm_name"
        exit 0
    fi
fi

# If an existing VM is selected, ask if the user wants to modify its parameters
read -p "Do you want to modify the VM parameters? (y/n): " modify_vm_params
if [[ $modify_vm_params =~ ^[Yy]$ ]]; then
    get_vm_parameters
fi

# Start the VM
start_vm "$vm_name"

echo "Script execution completed."
