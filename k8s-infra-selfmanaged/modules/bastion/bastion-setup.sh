#!/bin/bash

# Bastion Host Setup Script
# This script sets up the bastion host with necessary tools and configurations

set -e

# Update system
yum update -y

# Install required packages
yum install -y \
    curl \
    wget \
    git \
    htop \
    vim \
    telnet \
    nc \
    jq

# Create SSH directory and set permissions
mkdir -p /home/${AWS_USER}/.ssh
chmod 700 /home/${AWS_USER}/.ssh
chown ${AWS_USER}:${AWS_USER} /home/${AWS_USER}/.ssh

# Set password for the user
echo "${AWS_USER}:${AWS_PASSWORD}" | chpasswd

# Enable password authentication for SSH (temporarily)
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Create a simple script to help with SSH tunneling
cat > /home/${AWS_USER}/ssh-tunnel.sh << 'EOF'
#!/bin/bash
# SSH Tunnel Helper Script

if [ $# -ne 2 ]; then
    echo "Usage: $0 <private_ip> <local_port>"
    echo "Example: $0 10.10.67.93 2222"
    echo "Then connect to localhost:2222 to access the private instance"
    exit 1
fi

PRIVATE_IP=$1
LOCAL_PORT=$2

echo "Setting up SSH tunnel..."
echo "Private IP: $PRIVATE_IP"
echo "Local Port: $LOCAL_PORT"
echo "Connect to: localhost:$LOCAL_PORT"
echo ""
echo "Press Ctrl+C to stop the tunnel"

ssh -L $LOCAL_PORT:$PRIVATE_IP:22 -N ${AWS_USER}@$PRIVATE_IP
EOF

chmod +x /home/${AWS_USER}/ssh-tunnel.sh
chown ${AWS_USER}:${AWS_USER} /home/${AWS_USER}/ssh-tunnel.sh

# Create a connection helper script
cat > /home/${AWS_USER}/connect-to-k8s.sh << 'EOF'
#!/bin/bash
# Kubernetes Connection Helper

echo "Available Kubernetes instances:"
echo "1. Control Plane (Master)"
echo "2. Worker Node"
echo ""
read -p "Select instance type (1 or 2): " choice

case $choice in
    1)
        echo "Connecting to Control Plane..."
        echo "Available control plane instances:"
        # This would be populated with actual IPs
        echo "10.10.67.93 - Master Node 1"
        ;;
    2)
        echo "Connecting to Worker Node..."
        echo "Available worker instances:"
        # This would be populated with actual IPs
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
EOF

chmod +x /home/${AWS_USER}/connect-to-k8s.sh
chown ${AWS_USER}:${AWS_USER} /home/${AWS_USER}/connect-to-k8s.sh

# Log completion
echo "Bastion host setup completed at $(date)" >> /var/log/bastion-setup.log
