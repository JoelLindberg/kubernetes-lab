#!/bin/bash
# We copy our images and public ssh key to `/var/lib/libvirt/images/` 
# because qemu is not allowed to access them in our /home/$USER folder 
# due to QEMU+AppArmor isolation (which is a good thing).


# Deployment configuration for QEMU VMs
export K3S_LAB_SSH_KEY=$(cat /var/lib/libvirt/images/kubernetes-lab.pub)
TEMPLATE="cloud-config.yml.tmpl"
#CLOUDCONFIG="/var/lib/libvirt/images/cloud-config.yml"
URL="https://repo.almalinux.org/almalinux/10/cloud/x86_64/images/AlmaLinux-10-GenericCloud-latest.x86_64.qcow2"
IMAGE="/var/lib/libvirt/images/AlmaLinux-10-GenericCloud-latest.x86_64.qcow2"
DOWNLOADS="$HOME/Downloads/$(basename "$IMAGE")"
NODES=("k3s1" "k3s2" "k3s3")


# Check if public key exists in libvirt images, copy from ~/.ssh if needed, or generate
if [ ! -f "/var/lib/libvirt/images/kubernetes-lab.pub" ]; then
    if [ -f "$HOME/.ssh/kubernetes-lab.pub" ]; then
        echo "Copying SSH key from ~/.ssh to libvirt images..."
        cp "$HOME/.ssh/kubernetes-lab.pub" "/var/lib/libvirt/images/kubernetes-lab.pub"
    else
        echo "SSH key not found in ~/.ssh/kubernetes-lab.pub"
        read -p "Generate new SSH key? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -f "$HOME/.ssh/kubernetes-lab" -N ""
            cp "$HOME/.ssh/kubernetes-lab.pub" "/var/lib/libvirt/images/kubernetes-lab.pub"
            echo "SSH key generated and copied."
        else
            echo "Error: SSH key required to proceed."
            exit 1
        fi
    fi
fi


# Use 'envsubst' to create the usable file (Standard on Ubuntu)
# This replaces ${K3S_LAB_SSH_KEY} with your actual key
#envsubst < "$TEMPLATE" > "$CLOUDCONFIG"


# Check if image exists, copy from Downloads if needed, or prompt to download
if [ ! -f "$IMAGE" ]; then
    if [ -f "$DOWNLOADS" ]; then
        echo "Copying image from Downloads to libvirt images..."
        cp "$DOWNLOADS" "$IMAGE"
    else
        echo "Image not found in Downloads folder."
        read -p "Download from repo.almalinux.org? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            wget -O "$IMAGE" "$URL"
        else
            echo "Error: Image file required to proceed."
            exit 1
        fi
    fi
fi


# Launch your nodes
echo "------------------------------------------------"
for NODE in "${NODES[@]}"; do
    echo "Deploying $NODE via virt-install..."
    
    export NODE_NAME="$NODE"
    envsubst < "$TEMPLATE" > "/var/lib/libvirt/images/cloud-config_${NODE}.yml"

    virt-install \
     	--connect qemu:///system \
        --name "$NODE" \
        --memory 4096 \
        --vcpus 4 \
        --os-variant almalinux10 \
	--cpu host-passthrough \
        --disk size=10,backing_store="$IMAGE",bus=virtio \
        --cloud-init user-data="/var/lib/libvirt/images/cloud-config_${NODE}.yml" \
        --network bridge=virbr0 \
        --graphics spice \
	--console pty,target_type=serial \
        --import \
        --noautoconsole

done

echo "------------------------------------------------"
echo "All nodes are up! Check status with 'virsh list --all'"
