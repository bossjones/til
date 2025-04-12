#!/bin/bash

# Define the VM ID to delete
VMID=101

echo "Starting deletion process for VM ID $VMID..."

# Step 1: Stop the VM (if running)
echo "Stopping VM $VMID if it is running..."
qm stop $VMID 2>/dev/null

# Step 2: Destroy the VM
echo "Destroying VM $VMID..."
qm destroy $VMID --purge || { echo "Failed to destroy VM $VMID. Exiting."; exit 1; }

# Step 3: Check for and delete associated ZFS disks
echo "Checking for associated ZFS disks for VM $VMID..."
DISKS=$(zfs list -H -o name | grep "vm-$VMID-disk")

if [ -n "$DISKS" ]; then
  echo "Found the following disks to delete:"
  echo "$DISKS"
  
  for DISK in $DISKS; do
    echo "Deleting disk $DISK..."
    zfs destroy -f $DISK || { echo "Failed to delete disk $DISK. Exiting."; exit 1; }
  done
else
  echo "No associated ZFS disks found for VM $VMID."
fi

# Step 4: Verify deletion and reclaimed space
echo "Verifying deletion of VM $VMID..."
qm list | grep -w $VMID && { echo "VM $VMID still exists. Something went wrong."; exit 1; }

echo "Checking available disk space..."
df -h

echo "Deletion process for VM ID $VMID completed successfully!"

