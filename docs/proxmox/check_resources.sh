#!/bin/bash

# Define the node name (replace with your actual node name)
NODE_NAME="pve1"

echo "======================================"
echo " Proxmox Resource Audit Script"
echo "======================================"

# Step 1: Check CPU and Memory Status
echo "Checking CPU and Memory resources on node $NODE_NAME..."
pvesh get /nodes/$NODE_NAME/status
echo ""

# Step 2: Display Real-Time CPU and Memory Usage
echo "Real-time CPU and Memory usage:"
top -n 1
echo ""

# Step 3: Check Storage Availability
echo "Checking storage availability..."
pvesm status
echo ""

# Step 4: Inspect Specific Storage Pool (Optional)
# Replace 'backups1' with the name of the storage pool you want to inspect.
STORAGE_POOL="backups1"
echo "Inspecting specific storage pool $STORAGE_POOL..."
pvesm list $STORAGE_POOL
echo ""

# Step 5: Check LVM-thin Storage Usage (if applicable)
echo "Checking LVM-thin storage usage..."
lvs
echo ""

# Summary message
echo "======================================"
echo " Resource audit completed."
echo "======================================"

