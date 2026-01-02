# Nicklab01 Build Directions

## System Overview
**Hostname:** Nicklab01  
**Purpose:** K3s Kubernetes cluster node with container workloads, GitLab runner, and cloud storage integration  
**Platform:** Oracle Cloud Infrastructure (ARM-based)

---

## Hardware Specifications

### Compute
- **Architecture:** ARM64 (aarch64)
- **CPU:** ARM Neoverse-N1
- **vCPUs:** 4 cores
- **Memory:** 24GB RAM
- **Swap:** None configured

### Storage
- **Boot Disk:** 46.6GB with LVM
  - `/dev/sda1`: 100MB (EFI boot partition)
  - `/dev/sda2`: 2GB (boot partition, XFS)
  - `/dev/sda3`: 44.5GB (LVM physical volume)
    - `ocivolume-root`: 29.5GB mounted at `/` (XFS)
    - `ocivolume-oled`: 15GB mounted at `/var/oled` (XFS)

### Network
- **Primary Interface:** enp0s6
- **IP Address:** 10.0.0.18/24
- **Container Networks:**
  - Flannel: 10.42.0.0/32
  - CNI bridge: 10.42.0.1/24
  - Docker bridge: 172.17.0.1/16

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

2. **Docker** (v29.1.2)
   - Package: moby-containerd-1.7.29-1.el9.aarch64
   - Plugins:
     - docker-buildx-plugin-0.30.1
     - docker-compose-plugin-5.0.0

3. **Kubectl** (installed at /usr/local/bin/kubectl)

### CI/CD
4. **GitLab Runner** (v18.6.6-1.aarch64)
   - Package: gitlab-runner-18.6.6-1.aarch64
   - Helper Images: gitlab-runner-helper-images-18.6.6-1
   - Working Directory: /home/gitlab-runner

### Cloud Storage
5. **Rclone** (mounted Google Drive)
   - Mount Point: /mnt/gdrive
   - Remote: gdrive:/
   - Size: 2TB (170GB used)

### SELinux Support
6. **k3s-selinux** (1.6-1.el9.noarch)

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
- **docker-ce-stable** - Docker CE Stable (aarch64)
- **kubernetes** - Kubernetes repository
- **rancher-k3s-common-stable** - Rancher K3s Common (stable)
- **runner_gitlab-runner** - GitLab Runner
- **packages-microsoft-com-prod** - Microsoft Production

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

---

## Systemd Services

### Custom Services (in /etc/systemd/system/)
1. **k3s.service** - Lightweight Kubernetes
2. **rclone-gdrive.service** - RClone mount for Google Drive
3. **gitlab-runner.service** - GitLab Runner
4. **docker.service** - Docker daemon
5. **containerd.service** - Containerd runtime

### Enabled Services at Boot
- atd.service
- auditd.service
- chronyd.service
- cloud-config.service
- cloud-final.service
- cloud-init-local.service
- cloud-init.service
- containerd.service
- crond.service
- docker.service
- firewalld.service
- gitlab-runner.service
- irqbalance.service
- k3s.service
- NetworkManager.service

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
- **Metrics Server** - Resource metrics
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
- **ACME HTTP solvers** - Certificate validation

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
- ACME HTTP challenge solvers

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
- **Boot Volume:** 47GB
- **OS:** Oracle Linux 9.7 (aarch64)
- **Network:** Same VCN/subnet or configure cluster networking

### 2. Configure Repositories
```bash
# Docker CE repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

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
