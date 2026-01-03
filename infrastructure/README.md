# Nicklab Infrastructure Configuration

This directory contains infrastructure-as-code configurations for the Nicklab K3s HA cluster running on Oracle Cloud Free Tier.

## Architecture

**4-Node HA Cluster:**
- **Nicklab01**: 1 OCPU, 6GB RAM - K3s Server (MASTER with Keepalived)
- **Nicklab02**: 1 OCPU, 6GB RAM - K3s Server (BACKUP with Keepalived)
- **Nicklab03**: 1 OCPU, 6GB RAM - PostgreSQL Primary
- **Nicklab04**: 1 OCPU, 6GB RAM - PostgreSQL Replica

**Total Resources**: 4 OCPUs, 24GB RAM, 200GB storage (100% of Oracle Cloud Free Tier)

## Directory Structure

```
infrastructure/
├── keepalived/              # Keepalived HA configuration
│   ├── setup-keepalived-master.sh    # Configure Nicklab01 as MASTER
│   └── setup-keepalived-backup.sh    # Configure Nicklab02 as BACKUP
├── cloud-init/              # Cloud-init configs for Oracle Cloud
│   ├── nicklab03-postgresql-primary.yaml
│   ├── nicklab04-postgresql-replica.yaml (to be added)
│   └── nicklab02-k3s-keepalived.yaml (to be added)
└── README.md                # This file
```

## Keepalived Virtual IP Failover

### Overview
Keepalived provides automatic failover using a Virtual IP (VIP) that floats between Nicklab01 and Nicklab02.

**Configuration:**
- **VIP**: `10.0.0.100/24` (customizable)
- **Nicklab01**: MASTER (priority 100)
- **Nicklab02**: BACKUP (priority 90)
- **Failover Time**: 5-10 seconds
- **Health Check**: K3s API `/livez` endpoint every 2 seconds

### Installation

**Option 1: Manual Setup (Recommended for Nicklab01)**

On Nicklab01 (after K3s is installed):
```bash
cd ~/
curl -O https://raw.githubusercontent.com/nbucking/nbucking-automation/main/infrastructure/keepalived/setup-keepalived-master.sh
chmod +x setup-keepalived-master.sh
sudo ./setup-keepalived-master.sh 10.0.0.100 YourSecretPassword
```

On Nicklab02 (after K3s is installed):
```bash
cd ~/
curl -O https://raw.githubusercontent.com/nbucking/nbucking-automation/main/infrastructure/keepalived/setup-keepalived-backup.sh
chmod +x setup-keepalived-backup.sh
sudo ./setup-keepalived-backup.sh 10.0.0.100 YourSecretPassword
```

**Option 2: Cloud-Init (Automated for Nicklab02)**

Use `cloud-init/nicklab02-k3s-keepalived.yaml` when provisioning Nicklab02 in Oracle Cloud.

### Verification

Check VIP assignment:
```bash
# On Nicklab01 - Should show VIP
ip addr show ens3 | grep 10.0.0.100

# Check keepalived status
sudo systemctl status keepalived
sudo journalctl -u keepalived -n 50
```

Test failover:
```bash
# On Nicklab01 - Stop K3s to trigger failover
sudo systemctl stop k3s

# Wait 5-10 seconds, then check VIP on Nicklab02
# On Nicklab02
ip addr show ens3 | grep 10.0.0.100  # Should now show VIP

# Verify connectivity
ping -c 3 10.0.0.100
curl -k https://10.0.0.100:6443/livez

# Restart K3s on Nicklab01
sudo systemctl start k3s
# VIP should migrate back to Nicklab01
```

### DNS Configuration

Update your DNS provider to point to the VIP:
```
A record: nbucking.net → 10.0.0.100
```

## Cloud-Init Configurations

### Nicklab03 - PostgreSQL Primary

Provisions a PostgreSQL 15 server as the primary K3s datastore.

**Features:**
- PostgreSQL 15 with K3s optimizations
- Database: `k3s`, User: `k3s`
- Listens on all interfaces (10.0.0.0/24)
- 4GB swap file
- Firewall configured for PostgreSQL

**Usage:**
1. Create Oracle Cloud instance with 1 OCPU, 6GB RAM, 50GB disk
2. Paste `nicklab03-postgresql-primary.yaml` into cloud-init field
3. Note the instance's IP address
4. Connection string: `postgres://k3s:K3sP0stgr3sSecr3t!@<ip>:5432/k3s?sslmode=disable`

### Nicklab04 - PostgreSQL Replica (Coming Soon)

Provisions a PostgreSQL replica with streaming replication from Nicklab03.

### Nicklab02 - K3s Server with Keepalived (Coming Soon)

Provisions a K3s server node that joins the cluster and includes keepalived configuration.

## Benefits

**High Availability:**
- ✓ Survives any single node failure (K3s OR PostgreSQL)
- ✓ Automatic VIP failover (5-10 seconds)
- ✓ Health-check based (only healthy nodes serve traffic)

**Cost Efficiency:**
- ✓ 100% Oracle Cloud Free Tier utilization
- ✓ No paid load balancer required
- ✓ Balanced 6GB RAM per node

**Simplicity:**
- ✓ No etcd complexity (PostgreSQL handles state)
- ✓ Standard VRRP protocol (widely supported)
- ✓ Single DNS entry (no round-robin issues)

## Troubleshooting

### Keepalived Issues

**VIP not appearing:**
1. Check service: `sudo systemctl status keepalived`
2. View logs: `sudo journalctl -u keepalived -f`
3. Test health check: `sudo /usr/local/bin/check_k3s.sh && echo OK`
4. Verify firewall: `sudo firewall-cmd --list-all`

**Split-brain (both nodes claim MASTER):**
- Ensure both nodes have same VRRP password
- Check network connectivity between nodes
- Verify VRRP packets: `sudo tcpdump -i ens3 vrrp`

### PostgreSQL Issues

**Connection failures:**
```bash
# Test from K3s node
psql -h <nicklab03-ip> -U k3s -d k3s -c "SELECT version();"

# Check PostgreSQL status
sudo systemctl status postgresql-15

# Verify firewall
sudo firewall-cmd --list-services
```

## Related Documentation

- [Nicklab01 Build Guide](../docs/nicklab01-build-guide.md)
- [HA Cluster Plan](../docs/nicklab-ha-cluster-plan.md) (if available)
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [K3s Documentation](https://docs.k3s.io/)
- [Keepalived Documentation](https://www.keepalived.org/)

## Credits

Built for the Nicklab K3s HA cluster on Oracle Cloud Free Tier.
Architecture: 2x K3s + 2x PostgreSQL with keepalived VIP failover.

Last Updated: January 2026
