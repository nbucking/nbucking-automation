# Nicklab01 Build Directions

## System Overview
**Hostname:** Nicklab01  
**Purpose:** K3s Kubernetes cluster node with container workloads, GitLab runner, and cloud storage integration  
**Platform:** Oracle Cloud Infrastructure (ARM-based)  
**Last Updated:** January 2, 2026

---

## Hardware Specifications

### Compute
- **Architecture:** ARM64 (aarch64)
- **CPU:** ARM Neoverse-N1
- **vCPUs:** 4 cores
- **Memory:** 24GB RAM
- **Swap:** 5GB (active)

### Storage
- **Boot Disk:** 50GB with LVM (expanded from 46.6GB)
  - `/dev/sda1`: 100MB (EFI boot partition)
  - `/dev/sda2`: 2GB (boot partition, XFS)
  - `/dev/sda3`: 47.9GB (LVM physical volume)
    - `ocivolume-root`: 45.9GB mounted at `/` (XFS) - **Optimized**
    - `ocivolume-oled`: 2GB mounted at `/var/oled` (XFS) - **Reduced from 15GB**

### Network
- **Primary Interface:** enp0s6
- **IP Address:** 10.0.0.18/24
- **Container Networks:**
  - Flannel: 10.42.0.0/32
  - CNI bridge: 10.42.0.1/24

---

## Operating System

### Base OS
- **Distribution:** Oracle Linux Server 9.7
- **Platform:** el9
- **Kernel:** 6.12.0-105.51.5.1.el9uek.aarch64 (UEK R8)
- **SELinux:** Enabled and Enforcing
- **Shell:** bash 5.1.8

---

## Software Stack

### Container & Orchestration
1. **K3s** (v1.33.6+k3s1)
   - Role: Single-node cluster (control-plane + master)
   - Container Runtime: containerd 2.1.5-k3s1.33
   - Network Plugin: Flannel
   - Package: Installed via Rancher K3s repository

2. **Kubectl** (installed at /usr/local/bin/kubectl)

### CI/CD
3. **GitLab Runner** (v18.6.6-1.aarch64)
   - Package: gitlab-runner-18.6.6-1.aarch64
   - Helper Images: gitlab-runner-helper-images-18.6.6-1
   - Working Directory: /home/gitlab-runner
   - Executor: shell
   - Uses Kaniko for container builds (no Docker daemon required)

### Cloud Storage
4. **Rclone** (mounted Google Drive)
   - Mount Point: /mnt/gdrive
   - Remote: gdrive:/
   - Size: 2TB (170GB used)

### SELinux Support
5. **k3s-selinux** (1.6-1.el9.noarch)

---

## YUM/DNF Repositories

Enable the following repositories:
- **ol9_baseos_latest** - Oracle Linux 9 BaseOS Latest
- **ol9_appstream** - Oracle Linux 9 Application Stream Packages
- **ol9_UEKR8** - Oracle Linux 9 UEK Release 8
- **ol9_addons** - Oracle Linux 9 Addons
- **ol9_codeready_builder** - Oracle Linux 9 CodeReady Builder
- **ol9_developer_EPEL** - Oracle Linux 9 EPEL Packages
- **ol9_oci_included** - Oracle Linux 9 OCI Included Packages
- **ol9_ksplice** - Ksplice for Oracle Linux 9
- **kubernetes** - Kubernetes repository
- **rancher-k3s-common-stable** - Rancher K3s Common (stable)
- **runner_gitlab-runner** - GitLab Runner
- **packages-microsoft-com-prod** - Microsoft Production

**Note:** Docker repositories not needed - GitLab Runner uses Kaniko for builds

---

## Firewall Configuration

### Firewalld Rules (public zone)
- **SSH:** 22/tcp (enabled via service)
- **HTTP:** 80/tcp
- **HTTPS:** 443/tcp
- **K8s API:** 6443/tcp
- **DHCPv6 Client:** enabled
- **Masquerade:** No
- **Forward:** Yes

### Firewalld Rules (trusted zone)
- **cni0** - K3s CNI bridge interface
- **flannel.1** - K3s Flannel VXLAN interface

**Critical:** K3s network interfaces must be in trusted zone for metrics-server and pod-to-kubelet communication.

---

## Systemd Services

### Custom Services (in /etc/systemd/system/)
1. **k3s.service** - Lightweight Kubernetes
2. **rclone-gdrive.service** - RClone mount for Google Drive
3. **gitlab-runner.service** - GitLab Runner

### Enabled Services at Boot
- atd.service
- auditd.service
- chronyd.service
- cloud-config.service
- cloud-final.service
- cloud-init-local.service
- cloud-init.service
- crond.service
- firewalld.service
- gitlab-runner.service
- irqbalance.service
- k3s.service
- NetworkManager.service

**Note:** Docker and PCP services removed - not required for this configuration

---

## K3s Configuration

### Cluster Details
- **Node Name:** nicklab01
- **Status:** Ready
- **Roles:** control-plane, master
- **Version:** v1.33.6+k3s1
- **Internal IP:** 10.0.0.18
- **OS:** Oracle Linux Server 9.7
- **Container Runtime:** containerd://2.1.5-k3s1.33

### K3s Service Configuration
- **Binary:** /usr/local/bin/k3s
- **Command:** `k3s server`
- **Restart Policy:** Always (5s interval)
- **Kernel Modules:** br_netfilter, overlay

### Installed Components
- **CoreDNS** - DNS service
- **Traefik** - Ingress controller (LoadBalancer on 10.0.0.18:80,443)
- **Metrics Server** - Resource metrics (requires trusted zone firewall config)
- **Local Path Provisioner** - Dynamic volume provisioning
- **Flannel** - CNI networking

### Namespaces
- default
- kube-system
- kube-public
- kube-node-lease
- cert-manager
- nbucking (custom)

---

## Deployed Applications (K3s Pods)

### cert-manager Namespace
- cert-manager (1 replica)
- cert-manager-cainjector (1 replica)
- cert-manager-webhook (1 replica)

### default Namespace
- **nbucking-web** (2 replicas) - Web application
- **webtop** (1 replica) - Web-based desktop
- **oauth2-proxy** (1 replica) - Authentication proxy

### kube-system Namespace
- **coredns** - DNS
- **local-path-provisioner** - Storage
- **metrics-server** - Metrics
- **traefik** - Ingress
- **svclb-traefik** - Service load balancer

---

## Ingress Configuration

### Domains Served
- **nbucking.net**
- **www.nbucking.net**
- **traefik.nbucking.net**

### Ingress Resources
- nbucking-web (traefik class, ports 80/443)
- oauth2 (traefik class, ports 80/443)
- webtop (traefik class, ports 80/443)

---

## Rclone Google Drive Mount

### Service Configuration (/etc/systemd/system/rclone-gdrive.service)
```ini
[Unit]
Description=RClone mount for Google Drive
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=opc
Group=opc
ExecStartPre=/bin/mkdir -p /mnt/gdrive
ExecStart=/usr/bin/rclone mount gdrive:/ /mnt/gdrive \
  --config=/home/opc/.config/rclone/rclone.conf \
  --vfs-cache-mode writes \
  --vfs-cache-max-age 24h \
  --vfs-cache-max-size 2G \
  --allow-other \
  --dir-cache-time 96h \
  --poll-interval 15s \
  --umask 002
ExecStop=/bin/fusermount -u /mnt/gdrive
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Rclone Configuration (~/.config/rclone/rclone.conf)
```ini
[gdrive]
type = drive
scope = drive
# Add client_id, client_secret, and token during setup
```

---

## Installation Steps for Second Node

### 1. Provision Oracle Cloud Instance
- **Shape:** VM.Standard.A1.Flex (ARM-based)
- **CPUs:** 4 OCPUs
- **Memory:** 24GB
- **Boot Volume:** 50GB minimum (recommend 50-60GB for growth)
- **OS:** Oracle Linux 9.7 (aarch64)
- **Network:** Same VCN/subnet or configure cluster networking

### 2. Configure Repositories
```bash
# GitLab Runner repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash

# Rancher K3s repository
curl -sfL https://rpm.rancher.io/public.key | sudo rpm --import -
cat <<EOF | sudo tee /etc/yum.repos.d/rancher-k3s-common.repo
[rancher-k3s-common-stable]
name=Rancher K3s Common (stable)
baseurl=https://rpm.rancher.io/k3s/stable/common/centos/9/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF
```

### 3. Install Base Packages
```bash
sudo dnf install -y \
  k3s-selinux \
  gitlab-runner \
  gitlab-runner-helper-images \
  rclone \
  fuse
```

**Note:** Docker is NOT needed - GitLab Runner uses shell executor with Kaniko for builds.

### 4. Install K3s
For cluster setup, decide if this is a **server** (control-plane) or **agent** (worker) node.

**Option A: Additional Server Node (HA setup)**
```bash
# Get token from first node
sudo cat /var/lib/rancher/k3s/server/node-token

# Install on second node
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.18:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

**Option B: Agent/Worker Node**
```bash
# Get token from first node
sudo cat /var/lib/rancher/k3s/server/node-token

# Install as agent
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.18:6443 K3S_TOKEN=<NODE_TOKEN> sh -s - agent
```

**Option C: Standalone Server Node (separate cluster)**
```bash
curl -sfL https://get.k3s.io | sh -
```

### 5. Configure Firewall
```bash
# Add standard ports
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-service=ssh

# CRITICAL: Add K3s network interfaces to trusted zone
sudo firewall-cmd --permanent --zone=trusted --add-interface=cni0
sudo firewall-cmd --permanent --zone=trusted --add-interface=flannel.1

# Reload firewall
sudo firewall-cmd --reload
```

**Important:** Without trusted zone configuration, metrics-server will fail with "no route to host" errors.

### 6. Setup Swap Space
```bash
# Create 5GB swap file
sudo fallocate -l 5G /.swapfile
sudo chmod 600 /.swapfile
sudo mkswap /.swapfile
sudo swapon /.swapfile

# Add to fstab for persistence
echo '/.swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 7. Setup Rclone Google Drive Mount
```bash
# Create rclone config directory
mkdir -p ~/.config/rclone

# Configure Google Drive remote (interactive)
rclone config

# Create systemd service
sudo cp /path/to/rclone-gdrive.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now rclone-gdrive.service
```

### 8. Configure GitLab Runner
```bash
# Register runner (replace with your GitLab URL and registration token)
sudo gitlab-runner register
# When prompted:
# - Executor: shell
# - Tags: choose appropriate tags (e.g., "figaro" for deploy jobs)

sudo systemctl enable --now gitlab-runner
```

### 9. Verify Services
```bash
# Check K3s
sudo systemctl status k3s
sudo /usr/local/bin/k3s kubectl get nodes

# Verify metrics-server is working
sudo /usr/local/bin/k3s kubectl top nodes

# Check Rclone mount
mount | grep gdrive
ls /mnt/gdrive

# Check GitLab Runner
sudo systemctl status gitlab-runner

# Verify swap
swapon --show
free -h
```

### 10. Deploy cert-manager (if standalone)
```bash
sudo /usr/local/bin/k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

---

## System Optimizations Applied

### Storage Layout
**Original Configuration:**
- Root: 30GB (89% used - critical!)
- /var/oled: 15GB (3% used - wasted)

**Optimized Configuration:**
- Root: 46GB (56% used - healthy)
- /var/oled: 2GB (3% used - adequate)
- **Total improvement:** +16GB usable space

**How to Replicate:**
1. Start with 50GB boot volume (not 46.6GB)
2. During LVM setup, allocate:
   - Root: 45-46GB
   - /var/oled: 2-3GB (only needed for Oracle monitoring if used)

### Swap Space
- 5GB swap file at `/.swapfile`
- Provides memory buffer for load spikes
- Prevents OOM killer from terminating pods

### Removed Services
The following are NOT needed and should be omitted:
- **Docker daemon** - GitLab Runner uses shell executor with Kaniko
- **PCP (Performance Co-Pilot)** - Oracle's monitoring tool, not used
  - Saves ~20MB packages + 300MB data

---

## Cluster Networking Considerations

For a **proper cluster** with multiple nodes:

1. **Ensure network connectivity** between nodes on port 6443
2. **Update firewall rules** to allow K3s cluster traffic:
   - K3s server: 6443/tcp (API)
   - K3s metrics: 10250/tcp
   - Flannel VXLAN: 8472/udp
3. **Add K3s interfaces to trusted zone on all nodes:**
   ```bash
   sudo firewall-cmd --permanent --zone=trusted --add-interface=cni0
   sudo firewall-cmd --permanent --zone=trusted --add-interface=flannel.1
   sudo firewall-cmd --reload
   ```
4. **Configure load balancer** or update DNS to point to multiple nodes
5. **Share storage** considerations (evaluate if PVCs need shared storage like Longhorn or NFS)

---

## Important Notes

1. **Tokens & Secrets:** You'll need to obtain and configure:
   - K3s node token (from /var/lib/rancher/k3s/server/node-token)
   - GitLab runner registration token
   - Google Drive OAuth credentials for rclone
   - TLS certificates (cert-manager will handle Let's Encrypt)

2. **SELinux:** Keep SELinux in enforcing mode; k3s-selinux package provides required policies

3. **Hostname:** Change hostname to distinguish nodes:
   ```bash
   sudo hostnamectl set-hostname nicklab02
   ```

4. **Storage:** For clustered storage, consider:
   - Longhorn (distributed block storage)
   - NFS for shared volumes
   - Oracle Cloud Block Volumes

5. **High Availability:** For HA control plane, you need:
   - Minimum 3 server nodes (odd number for etcd quorum)
   - External database or embedded etcd
   - Load balancer in front of API servers

6. **Firewall Configuration:** The trusted zone setup for cni0/flannel.1 is CRITICAL. Without it:
   - Metrics-server will fail with "no route to host"
   - Pod-to-kubelet communication will be blocked
   - `kubectl top` commands won't work

---

## Troubleshooting

### Metrics Server Not Ready (0/1)
**Symptom:** metrics-server pod shows 0/1 Ready, logs show "no route to host" when accessing port 10250

**Solution:**
```bash
# Add K3s network interfaces to firewall trusted zone
sudo firewall-cmd --permanent --zone=trusted --add-interface=cni0
sudo firewall-cmd --permanent --zone=trusted --add-interface=flannel.1
sudo firewall-cmd --reload

# Delete pod to restart
sudo /usr/local/bin/k3s kubectl delete pod -n kube-system -l k8s-app=metrics-server
```

### K3s Issues
```bash
# View k3s logs
sudo journalctl -u k3s -f

# Check node status
sudo /usr/local/bin/k3s kubectl get nodes -o wide

# Check pod status
sudo /usr/local/bin/k3s kubectl get pods --all-namespaces
```

### Networking Issues
```bash
# Check firewall rules
sudo firewall-cmd --list-all
sudo firewall-cmd --get-active-zones

# Test connectivity between nodes
ping <other-node-ip>
nc -zv <other-node-ip> 6443
```

### Storage Issues
```bash
# Check PVCs
sudo /usr/local/bin/k3s kubectl get pvc --all-namespaces

# Check PVs
sudo /usr/local/bin/k3s kubectl get pv

# Check disk usage
df -h /
```

### Disk Space Full
```bash
# Clean up container images
sudo /usr/local/bin/k3s crictl rmi --prune

# Clean package cache
sudo dnf clean all

# Vacuum journal logs
sudo journalctl --vacuum-time=7d
```

---

## Current Resource Usage (Reference)

As of January 2, 2026:

**Storage:**
- Root: 26GB used / 46GB total (56%)
- /var/oled: 47MB used / 2GB total (3%)

**Memory:**
- RAM: 4.4GB used / 22GB total (17%)
- Swap: 0B used / 5GB total

**CPU:**
- Usage: 5% (230m cores)

**K3s Pods:**
- 12 pods running across all namespaces
- All healthy (1/1 or 2/2 ready)

---

This documentation captures the complete optimized setup of Nicklab01 and provides step-by-step directions to build an identical or cluster-compatible second node.

**Document Generated:** January 2, 2026  
**Source System:** Nicklab01 (10.0.0.18)  
**Last Optimization:** January 2, 2026
