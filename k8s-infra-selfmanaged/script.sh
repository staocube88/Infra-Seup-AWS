#!/bin/bash

# run the script if error
LOG_FILE="/var/log/startup_script.log"

exec >> "$LOG_FILE" 2>&1
sleep 10
sudo rm -rf $HOME/.kube 
sudo mkdir -p $HOME/.kube
sleep 10
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sleep 10
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 10
sudo chmod 775 $HOME/.kube
sleep 10
sudo systemctl restart kubelet
sleep 15
cd /tmp

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml  --validate=false
sleep 15
sudo curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml -O 
sleep 15
kubectl create -f custom-resources.yaml --validate=false
echo "complete installation - check logs"
