#!/bin/bash

# Define the VM ID
VM_ID="102"

echo "======================================"
echo " Proxmox VM Details Script"
echo "======================================"
echo "Fetching details for VM ID: $VM_ID..."

# Step 1: Display VM Configuration
echo "--------------------------------------"
echo "VM Configuration:"
qm config $VM_ID
echo ""

# Step 2: Display VM Resource Usage
echo "--------------------------------------"
echo "VM Resource Usage:"
qm status $VM_ID
echo ""

# Step 3: Display Attached Disks and Storage Information
echo "--------------------------------------"
echo "Attached Disks and Storage Information:"
pvesm list | grep vm-$VM_ID-disk
echo ""

# Step 4: Display Filesystem Usage on Host (Optional)
echo "--------------------------------------"
echo "Host Filesystem Usage:"
df -h
echo ""

echo "======================================"
echo " VM Details Fetch Completed."
echo "======================================"

