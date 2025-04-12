#!/bin/bash
# Proxmox Ubuntu LTS VM Creation Script (Customized for gitops-lab1 Replacement)

### CONFIGURABLE PARAMETERS ###
VM_ID="103"                   # New unique VM ID
VM_NAME="gitops-lab2" # Display name
MEMORY="32048"                # Memory in MB (32GB)
CORES="8"                     # CPU cores
SOCKETS="1"                   # CPU sockets
DISK_SIZE="256G"              # Disk size (256GB)
STORAGE="local-lvm"           # Storage pool name
NET_BRIDGE="vmbr0"            # Network bridge
MAC_ADDRESS="C6:F9:2F:C5:50:42" # New MAC address (different from old VM)
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5z92gT4YFkAldHErkVfZKq2jPa6sNN87SyLY2jV0ljcXKkb1tyujX3CVgLz189tSuigqtR32gcnJNZCexqa67149/9qaGzWitb2Ry3rghSP+5VdQH5J0JC92YpHbC1lKiI/YADnFMC6SEWHgMvBXrrF9ZSGiQnRcg5AaVNDof06uG3Lhpxt5+ooihpjWX9xx1pYoAfQXDRUpZmQTsFwN+XdgS3mOWQoBsWsA9cofxWDELQhC2I2M+reYDW3s/8UpPxcVLcBu4oVzbkyER+8khLv1EC4XnWPhN1JX2W/FzmJ+fzqKgd0XOCdDK0/yj4rEQ8MZgQAHbMEINYaRWGKhr root@pve1"  # Your SSH public key
USERNAME="pi"               # Default user
# Generate a secure password hash instead of plain text
PASSWORD_HASH=$(openssl passwd -6 "$PROXMOX_ROOT_PASS")  # Replace "changeme" with your password
### END CONFIGURABLE PARAMETERS ###

# Ubuntu LTS image URL (auto-updates to latest LTS)
UBUNTU_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

echo "Starting Ubuntu LTS VM creation..."
echo "VM ID: $VM_ID | Name: $VM_NAME | Cores: $CORES | RAM: ${MEMORY}MB"

# Step 1: Create VM with basic configuration
qm create $VM_ID \
  --name "$VM_NAME" \
  --memory $MEMORY \
  --cores $CORES \
  --sockets $SOCKETS \
  --numa 0 \
  --net0 virtio,bridge=$NET_BRIDGE,macaddr=$MAC_ADDRESS,firewall=1 \
  --scsihw virtio-scsi-single

# Step 2: Create and attach disk
qm set $VM_ID \
  --scsi0 $STORAGE:$VM_ID-disk-0,size=$DISK_SIZE,discard=on,iothread=1,ssd=1

# Step 3: Download and attach Ubuntu cloud image
qm importdisk $VM_ID "$UBUNTU_URL" $STORAGE

# Step 4: Configure cloud-init
qm set $VM_ID \
  --ide2 $STORAGE:cloudinit \
  --sshkey "$SSH_KEY" \
  --ciuser $USERNAME \
  --cipassword "$PASSWORD" \
  --citype nocloud \
  --ipconfig0 ip=dhcp

# Step 5: Configure boot order and enable QEMU agent
qm set $VM_ID \
  --boot order=scsi0;net0 \
  --agent enabled=1,fstrim_cloned_disks=1

# Optional Step: Resize disk if needed (default cloud image size is small)
qm resize $VM_ID scsi0 $DISK_SIZE

echo "Ubuntu LTS VM creation complete!"
echo "Start the VM with the following command:"
echo "qm start $VM_ID"
