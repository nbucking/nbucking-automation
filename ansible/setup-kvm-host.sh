#!/bin/bash
#
# setup-kvm-host.sh
# Installs and configures KVM/libvirt virtualization on Fedora Linux
#
# Usage: sudo ./setup-kvm-host.sh
#

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "=== Setting up KVM/libvirt on Fedora ==="

# Check CPU virtualization support
echo "Checking CPU virtualization support..."
if grep -E '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    echo "✓ CPU virtualization is supported"
else
    echo "✗ CPU virtualization is NOT supported or not enabled in BIOS"
    echo "  Please enable VT-x (Intel) or AMD-V in your BIOS/UEFI settings"
    exit 1
fi

# Install virtualization packages
echo ""
echo "Installing KVM and virtualization packages..."
dnf install -y @virtualization \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt \
    libvirt-daemon-kvm \
    qemu-kvm \
    qemu-img \
    libguestfs-tools \
    python3-libvirt \
    bridge-utils

# Install Ansible if not present
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible..."
    dnf install -y ansible
fi

# Install required Python modules for Ansible
echo "Installing Python modules for Ansible..."
dnf install -y python3-lxml python3-libvirt

# Enable and start libvirtd
echo ""
echo "Enabling and starting libvirtd service..."
systemctl enable libvirtd
systemctl start libvirtd

# Add current user to libvirt group (if SUDO_USER is set)
if [ -n "$SUDO_USER" ]; then
    echo ""
    echo "Adding user $SUDO_USER to libvirt group..."
    usermod -aG libvirt "$SUDO_USER"
    echo "✓ User added to libvirt group (logout/login required for group to take effect)"
fi

# Configure default network
echo ""
echo "Configuring default libvirt network..."
virsh net-list --all | grep -q default || virsh net-define /usr/share/libvirt/networks/default.xml
virsh net-autostart default
virsh net-start default 2>/dev/null || echo "Default network already started"

# Create storage pool directory if it doesn't exist
echo ""
echo "Setting up storage pool..."
POOL_DIR="/var/lib/libvirt/images"
mkdir -p "$POOL_DIR"

# Define default storage pool if not exists
if ! virsh pool-list --all | grep -q default; then
    virsh pool-define-as default dir --target "$POOL_DIR"
    virsh pool-autostart default
    virsh pool-start default
else
    echo "Default storage pool already exists"
fi

# Create directory for ISO files
ISO_DIR="/var/lib/libvirt/isos"
mkdir -p "$ISO_DIR"
chmod 755 "$ISO_DIR"
echo "✓ ISO directory created: $ISO_DIR"

# Verify installation
echo ""
echo "=== Verification ==="
echo "Libvirt version: $(libvirtd --version | awk '{print $3}')"
echo "QEMU version: $(qemu-system-x86_64 --version | head -n1)"
virsh --version > /dev/null && echo "✓ virsh is working"
virsh net-list --all
virsh pool-list --all

echo ""
echo "=== KVM Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Download Windows Server 2019 ISO to: $ISO_DIR"
echo "   Example: wget -O $ISO_DIR/windows_server_2019.iso <ISO_URL>"
echo ""
echo "2. If you added your user to libvirt group, logout and login for changes to take effect"
echo ""
echo "3. Run the Ansible playbook to create the VM:"
echo "   ansible-playbook ansible/provision-windows-vm.yml"
echo ""
