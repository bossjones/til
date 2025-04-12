#!/bin/bash

echo "======================================"
echo " Proxmox Storage Audit Report"
echo "======================================"

# Run `pvesm status` to get storage information
STORAGE_STATUS=$(pvesm status)

# Print the raw output of `pvesm status`
echo "Raw Storage Status:"
echo "$STORAGE_STATUS"
echo ""

# Parse and format the storage data
echo "Formatted Storage Information:"
echo "--------------------------------------"
echo -e "Name\t\tType\tStatus\t\tTotal(GB)\tUsed(GB)\tAvailable(GB)\tUsage(%)"
echo "$STORAGE_STATUS" | tail -n +2 | while read -r line; do
    # Extract fields from the output
    NAME=$(echo "$line" | awk '{print $1}')
    TYPE=$(echo "$line" | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{print $3}')
    TOTAL=$(echo "$line" | awk '{print $4}')
    USED=$(echo "$line" | awk '{print $5}')
    AVAILABLE=$(echo "$line" | awk '{print $6}')
    PERCENT=$(echo "$line" | awk '{print $7}')

    # Convert Total, Used, and Available to GB for better readability
    if [[ "$TOTAL" != "0" && "$TOTAL" != "-" ]]; then
        TOTAL_GB=$((TOTAL / 1024 / 1024))
        USED_GB=$((USED / 1024 / 1024))
        AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))
    else
        TOTAL_GB="N/A"
        USED_GB="N/A"
        AVAILABLE_GB="N/A"
    fi

    # Print formatted data
    echo -e "${NAME}\t${TYPE}\t${STATUS}\t${TOTAL_GB}\t\t${USED_GB}\t\t${AVAILABLE_GB}\t\t${PERCENT}"
done

# Highlight disabled storages
DISABLED_STORAGES=$(echo "$STORAGE_STATUS" | grep "disabled")
if [[ -n "$DISABLED_STORAGES" ]]; then
    echo ""
    echo "Warning: The following storages are disabled:"
    echo "$DISABLED_STORAGES"
else
    echo ""
    echo "All storages are active."
fi

# Summary of active storage usage
echo ""
echo "Overall Disk Usage Summary:"
df -h | grep -E 'Filesystem|/dev/'

