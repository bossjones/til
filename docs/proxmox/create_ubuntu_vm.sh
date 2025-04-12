#!/bin/bash
# Proxmox Ubuntu LTS VM Creation Script
# Version 2.3 - With clear distinction between host and VM operations
# IMPORTANT: This script runs ON THE PROXMOX HOST to create a VM

#################################################
### CONFIGURABLE PARAMETERS - MODIFY AS NEEDED ###
#################################################
DRY_RUN="true"
# Basic VM Configuration
VM_ID="103"                   # Unique VM ID (change for each new VM)
VM_NAME="gitops-lab2" # Display name
MEMORY="32048"                  # Memory in MB (8GB recommended for Desktop)
BALLOON="2048"                 # Memory balloon minimum (2GB)
CORES="8"                      # CPU cores
DISK_SIZE="256G"                # Disk size (desktop needs more space)
STORAGE="local-lvm"            # Storage pool name
NET_BRIDGE="vmbr0"             # Network bridge
VLAN_TAG=""                    # VLAN tag (leave empty if not using VLAN)

# Authentication
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5z92gT4YFkAldHErkVfZKq2jPa6sNN87SyLY2jV0ljcXKkb1tyujX3CVgLz189tSuigqtR32gcnJNZCexqa67149/9qaGzWitb2Ry3rghSP+5VdQH5J0JC92YpHbC1lKiI/YADnFMC6SEWHgMvBXrrF9ZSGiQnRcg5AaVNDof06uG3Lhpxt5+ooihpjWX9xx1pYoAfQXDRUpZmQTsFwN+XdgS3mOWQoBsWsA9cofxWDELQhC2I2M+reYDW3s/8UpPxcVLcBu4oVzbkyER+8khLv1EC4XnWPhN1JX2W/FzmJ+fzqKgd0XOCdDK0/yj4rEQ8MZgQAHbMEINYaRWGKhr root@pve1"   # Your SSH public key (replace with actual key)
USERNAME="pi"               # Default user
# Check if PROXMOX_ROOT_PASS is set
if [ -z "$PROXMOX_ROOT_PASS" ]; then
    echo "ERROR: PROXMOX_ROOT_PASS environment variable is not set."
    echo "Please set it before running this script:"
    echo "export PROXMOX_ROOT_PASS=yourpassword"
    exit 1
fi
# Generate a secure password hash instead of plain text
PASSWORD_HASH=$(openssl passwd -6 "$PROXMOX_ROOT_PASS")  # Replace "changeme" with your password

# Additional Configuration
CPU_TYPE="host"                # CPU type (host = pass through CPU features)
MACHINE_TYPE="q35"             # Machine type (q35 is recommended for modern OSes)
OS_TYPE="l26"                  # OS type (l26 = Linux 2.6+)
START_ON_BOOT="yes"            # Auto-start VM on host boot (yes/no)
NUMA="yes"                     # Enable NUMA (yes/no, improves performance on multi-socket hosts)
KVM_ARGS="-cpu host,+aes"      # Additional KVM arguments

# DRY RUN Mode
# Set DRY_RUN=true to echo commands instead of executing them
DRY_RUN=${DRY_RUN:-false}      # Default to false if not set

###################################
### END CONFIGURABLE PARAMETERS ###
###################################

# Ubuntu Desktop ISO URL
UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-desktop-amd64.iso"
ISO_NAME="ubuntu-24.04.2-desktop-amd64.iso"
ISO_STORAGE="local"  # Storage location for ISO files
TMP_DIR="/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#################################################
### HELPER FUNCTIONS (RUN ON PROXMOX HOST)    ###
#################################################

# Run or echo command based on DRY_RUN setting
run_command() {
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would execute: $*"
        return 0
    else
        eval "$@"
        return $?
    fi
}

# Display section header
section() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

# Display info message
info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

# Display warning message
warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Display error message and exit
error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    exit 1
}

# Confirm action
confirm() {
    read -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Query system for available storage pools
get_available_storage_pools() {
    section "Available Storage Pools"
    pvesm list | grep -v "Name" | awk '{print $1}' | sort
}

# Query system for available network bridges
get_available_network_bridges() {
    section "Available Network Bridges"
    ip link show | grep -E '^[0-9]+: vmbr[0-9]+' | awk -F': ' '{print $2}'
}

# Query system for CPU cores
get_available_cpu_cores() {
    section "CPU Information"
    echo "Total CPU cores available: $(nproc)"
    info "Using $CORES cores for this VM"
}

# Query system for machine types
get_available_machine_types() {
    section "Available Machine Types"
    echo "Common machine types: q35, i440fx, pc"
    echo "Default Proxmox machine type: q35"
    echo "Currently selected: $MACHINE_TYPE"
}

# Get available VM IDs
get_next_available_vm_id() {
    section "VM ID Information"
    local used_ids=$(qm list | tail -n +2 | awk '{print $1}' | sort -n)
    echo "Currently used VM IDs:"
    if [ -z "$used_ids" ]; then
        echo "No VMs currently exist"
    else
        echo "$used_ids"
    fi

    # Suggest next available ID
    local next_id=100
    while echo "$used_ids" | grep -q "^$next_id$"; do
        next_id=$((next_id + 1))
    done
    echo "Next available VM ID: $next_id"
    echo "Currently selected: $VM_ID"
}

# Get total system memory
get_system_memory() {
    section "Memory Information"
    local total_mem=$(free -m | grep "Mem:" | awk '{print $2}')
    local available_mem=$(free -m | grep "Mem:" | awk '{print $7}')
    echo "Total system memory: ${total_mem}MB"
    echo "Available memory: ${available_mem}MB"
    echo "VM memory requested: ${MEMORY}MB"

    if [ "$MEMORY" -gt "$available_mem" ]; then
        warning "Requested memory ($MEMORY MB) exceeds available memory ($available_mem MB)"
    fi
}

# Validate VM parameters
validate_parameters() {
    section "Validating Parameters"

    # Validate VM ID
    if qm status $VM_ID &>/dev/null; then
        error "VM with ID $VM_ID already exists. Please choose a different VM_ID."
    fi
    info "VM ID $VM_ID is available"

    # Validate storage
    if ! pvesm list | grep -q "^$STORAGE"; then
        error "Storage '$STORAGE' does not exist. Available storage pools: $(pvesm list | grep -v 'Name' | awk '{print $1}' | paste -sd ',' -)"
    fi
    info "Storage '$STORAGE' exists"

    # Validate ISO storage
    if ! pvesm list | grep -q "^$ISO_STORAGE"; then
        error "ISO storage '$ISO_STORAGE' does not exist. Available storage pools: $(pvesm list | grep -v 'Name' | awk '{print $1}' | paste -sd ',' -)"
    fi
    info "ISO storage '$ISO_STORAGE' exists"

    # Validate network bridge
    if ! ip link show | grep -q "$NET_BRIDGE"; then
        error "Network bridge '$NET_BRIDGE' does not exist. Available bridges: $(ip link show | grep -E '^[0-9]+: vmbr[0-9]+' | awk -F': ' '{print $2}' | paste -sd ',' -)"
    fi
    info "Network bridge '$NET_BRIDGE' exists"

    # Validate machine type
    valid_machine_types=("q35" "i440fx" "pc")
    if ! echo "${valid_machine_types[@]}" | grep -q -w "$MACHINE_TYPE"; then
        warning "Machine type '$MACHINE_TYPE' may not be valid. Common types are: ${valid_machine_types[*]}"
        if ! confirm "Continue with machine type '$MACHINE_TYPE'?"; then
            error "Script aborted by user"
        fi
    else
        info "Machine type '$MACHINE_TYPE' is valid"
    fi

    # Validate memory
    local available_mem=$(free -m | grep "Mem:" | awk '{print $7}')
    if [ "$MEMORY" -gt "$available_mem" ]; then
        warning "Requested memory ($MEMORY MB) exceeds available memory ($available_mem MB)"
        if ! confirm "Continue with requested memory?"; then
            error "Script aborted by user"
        fi
    else
        info "Memory allocation is within available limits"
    fi

    # Validate CPU cores
    local total_cores=$(nproc)
    if [ "$CORES" -gt "$total_cores" ]; then
        warning "Requested cores ($CORES) exceeds available cores ($total_cores)"
        if ! confirm "Continue with requested cores?"; then
            error "Script aborted by user"
        fi
    else
        info "CPU core allocation is within available limits"
    fi

    return 0
}

#################################################
### MAIN SCRIPT (RUNS ON PROXMOX HOST)        ###
#################################################

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
   error "This script must be run as root on the Proxmox host"
fi

# Display script banner
section "Proxmox Ubuntu VM Creation Script"
echo "This script will create an Ubuntu 24.04.2 Desktop VM on Proxmox"
echo "NOTE: This script is running on the Proxmox host and will create a VM"

if [ "$DRY_RUN" = "true" ]; then
    info "DRY RUN MODE ACTIVE - Commands will be echoed but not executed"
fi

# Query and display system information
get_next_available_vm_id
get_available_storage_pools
get_available_network_bridges
get_available_cpu_cores
get_available_machine_types
get_system_memory

# Validate parameters
validate_parameters

# Show configuration summary and ask for confirmation
section "Configuration Summary"
echo "VM ID: $VM_ID"
echo "VM Name: $VM_NAME"
echo "Memory: ${MEMORY}MB"
echo "Balloon: ${BALLOON}MB"
echo "CPU Cores: $CORES"
echo "CPU Type: $CPU_TYPE"
echo "Disk Size: $DISK_SIZE"
echo "Storage: $STORAGE"
echo "Network Bridge: $NET_BRIDGE"
echo "Machine Type: $MACHINE_TYPE"
echo "ISO: $ISO_NAME"
echo "ISO Storage: $ISO_STORAGE"

if ! confirm "Do you want to proceed with this configuration?"; then
    echo "Script aborted by user"
    exit 0
fi

section "Creating VM on Proxmox"

# Download ISO if not already in Proxmox storage
if ! pvesm list $ISO_STORAGE | grep -q "$ISO_NAME"; then
    info "Downloading Ubuntu Desktop ISO..."
    run_command "wget -O \"$TMP_DIR/$ISO_NAME\" \"$UBUNTU_ISO_URL\"" || {
        error "Failed to download Ubuntu ISO"
    }

    # Upload ISO to Proxmox storage
    info "Uploading ISO to Proxmox storage..."
    run_command "pvesm upload $ISO_STORAGE iso \"$TMP_DIR/$ISO_NAME\"" || {
        error "Failed to upload ISO to Proxmox storage"
    }

    # Clean up downloaded ISO
    run_command "rm -f \"$TMP_DIR/$ISO_NAME\""
else
    info "ISO already exists in Proxmox storage"
fi

# Create VM with basic configuration
info "Creating VM with basic configuration..."
run_command "qm create $VM_ID \\
  --name \"$VM_NAME\" \\
  --memory $MEMORY \\
  --balloon $BALLOON \\
  --cores $CORES \\
  --cpu $CPU_TYPE \\
  --machine $MACHINE_TYPE \\
  --ostype $OS_TYPE \\
  --net0 virtio,bridge=$NET_BRIDGE${VLAN_TAG:+,tag=$VLAN_TAG} \\
  --onboot $START_ON_BOOT \\
  --scsihw virtio-scsi-pci \\
  --numa $NUMA \\
  --args \"$KVM_ARGS\"" || {
    error "Failed to create VM"
  }

# Create and attach disk
info "Creating disk..."
run_command "qm set $VM_ID \\
  --scsi0 $STORAGE:$DISK_SIZE,discard=on,iothread=1,ssd=1 \\
  --boot order=scsi0" || {
    error "Failed to create disk"
}

# Mount the ISO for installation
info "Mounting installation ISO..."
run_command "qm set $VM_ID \\
  --ide2 $ISO_STORAGE:iso/$ISO_NAME,media=cdrom \\
  --boot order=ide2,scsi0" || {
    error "Failed to mount ISO"
}

# Configure display and other settings
info "Configuring display and other settings..."
run_command "qm set $VM_ID \\
  --agent enabled=1 \\
  --vga std \\
  --serial0 socket" || {
    error "Failed to configure display settings"
}

# Create a post-installation script to be used after manual installation
info "Creating post-installation script to be run INSIDE THE VM later..."
cat > "$TMP_DIR/post_install_$VM_ID.sh" << 'EOF'
#!/bin/bash
#################################################
# POST-INSTALLATION SCRIPT FOR UBUNTU VM        #
# -------------------------------------------- #
# IMPORTANT: THIS SCRIPT IS MEANT TO RUN INSIDE #
# THE UBUNTU VM, NOT ON THE PROXMOX HOST.       #
# Run this after completing the Ubuntu Desktop  #
# installation from the ISO.                    #
#################################################

# Display banner
echo "=================================================="
echo "Ubuntu Desktop Post-Installation Setup"
echo "=================================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo "Error: This script must be run as root inside the VM (use sudo)" >&2
   exit 1
fi

echo "Installing QEMU Guest Agent in the VM..."
apt update
apt install -y qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

echo "Installing security tools inside the VM..."
apt install -y fail2ban unattended-upgrades

echo "Configuring automatic security updates inside the VM..."
cat > /tmp/20auto-upgrades << 'APTEND'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgrades "1";
APT::Periodic::AutocleanInterval "7";
APTEND
mv /tmp/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

echo "Configuring unattended-upgrades inside the VM..."
sed -i 's|//\s*"\${distro_id}:\${distro_codename}-updates"|    "\${distro_id}:\${distro_codename}-updates"|' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|//Unattended-Upgrade::Automatic-Reboot-Time "02:00";|Unattended-Upgrade::Automatic-Reboot-Time "02:00";|' /etc/apt/apt.conf.d/50unattended-upgrades

# Secure SSH if it's installed
if [ -f /etc/ssh/sshd_config ]; then
    echo "Securing SSH configuration inside the VM..."
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart ssh
fi

# Install fail2ban
echo "Setting up fail2ban inside the VM..."
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# System performance optimizations
echo "Applying system performance optimizations inside the VM..."
# Set swappiness to a lower value for better performance
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
# Apply sysctl settings
sysctl --system

echo "=================================================="
echo "Post-installation setup complete inside the VM!"
echo "The VM is now optimized and secured."
echo "=================================================="
EOF

chmod +x "$TMP_DIR/post_install_$VM_ID.sh"

# Success message
section "VM Creation Complete"
echo "VM ID: $VM_ID | Name: $VM_NAME"
echo
info "NEXT STEPS TO COMPLETE VM SETUP:"
echo "1. Start the VM with: qm start $VM_ID"
echo "2. Connect to VM console using Proxmox web UI and complete Ubuntu installation"
echo "3. After installation, run the post-installation script INSIDE THE VM:"
echo "   - Copy the script to the VM (using file transfer, shared folder, etc.)"
echo "   - Path to script ON THE PROXMOX HOST: $TMP_DIR/post_install_$VM_ID.sh"
echo "   - Run with: sudo bash post_install_$VM_ID.sh"
echo
info "POST-INSTALLATION STEPS (TO BE RUN ON THE PROXMOX HOST):"
echo "1. Change the boot order back to boot from disk first:"
echo "   qm set $VM_ID --boot order=scsi0"
echo "2. Optionally remove the installation ISO:"
echo "   qm set $VM_ID --ide2 none"
echo "----------------------------------------------------------------"
info "NOTE: This script created a VM using the Ubuntu Desktop ISO."
echo "You need to manually install Ubuntu using the VM console, then"
echo "run the post-installation script INSIDE THE VM to configure it properly."
echo "----------------------------------------------------------------"
