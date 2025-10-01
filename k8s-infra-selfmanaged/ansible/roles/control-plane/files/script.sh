#!/bin/bash

LOG_FILE="/var/log/startup_script.log"
KUBECONFIG="/home/ec2-user/.kube/config"

# Redirect stdout and stderr to log file
exec >> "$LOG_FILE" 2>&1

echo "===== Starting Calico installation: $(date) ====="

# Helper function to check command success
check_error() {
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: $1 failed. Exiting."
        exit 1
    fi
}

sleep 10
cd /tmp || exit 1

echo "Applying Tigera operator..."
KUBECONFIG="$KUBECONFIG" kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml --validate=false
check_error "Tigera operator apply"

sleep 15

echo "Downloading custom-resources.yaml..."
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml
check_error "custom-resources.yaml download"

sleep 15

echo "Applying custom resources..."
KUBECONFIG="$KUBECONFIG" kubectl create -f custom-resources.yaml --validate=false
check_error "custom-resources apply"

echo "✅ Calico installation complete - check $LOG_FILE"
