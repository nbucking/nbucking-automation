#!/bin/bash
# Keepalived Setup Script for Nicklab01 (MASTER)
# Usage: sudo ./setup-keepalived-master.sh <VIP> <PASSWORD>

set -e

VIP="${1:-10.0.0.100}"
AUTH_PASS="${2:-ChangeMe123!}"

echo "Installing keepalived..."
dnf install -y keepalived

echo "Creating keepalived configuration for MASTER..."
tee /etc/keepalived/keepalived.conf > /dev/null << EOF
global_defs {
    router_id NICKLAB01
    enable_script_security
}

vrrp_script check_k3s {
    script "/usr/local/bin/check_k3s.sh"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens3
    virtual_router_id 51
    priority 100
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    
    virtual_ipaddress {
        ${VIP}/24
    }
    
    track_script {
        check_k3s
    }
}
EOF

echo "Creating K3s health check script..."
tee /usr/local/bin/check_k3s.sh > /dev/null << 'EOF'
#!/bin/bash
# Check if K3s API is responding
if systemctl is-active --quiet k3s && \
   curl -k -s -o /dev/null -w "%{http_code}" https://localhost:6443/livez | grep -q 200; then
    exit 0
else
    exit 1
fi
EOF

chmod +x /usr/local/bin/check_k3s.sh

echo "Configuring firewall for VRRP..."
firewall-cmd --permanent --add-rich-rule='rule protocol value="vrrp" accept'
firewall-cmd --reload

echo "Enabling and starting keepalived..."
systemctl enable --now keepalived

echo "Waiting for VIP assignment..."
sleep 5

echo "Verifying VIP ${VIP}..."
if ip addr show ens3 | grep -q "${VIP}"; then
    echo "✓ VIP ${VIP} successfully assigned to Nicklab01 (MASTER)"
else
    echo "⚠ VIP not yet assigned. Check keepalived status:"
    echo "  sudo systemctl status keepalived"
    echo "  sudo journalctl -u keepalived -n 50"
fi

echo ""
echo "Keepalived setup complete!"
echo "Check status: sudo systemctl status keepalived"
echo "View logs: sudo journalctl -u keepalived -f"
