#!/bin/bash

# Define log file
export AWS_USER=${AWS_USER}
export AWS_PASSWORD=${AWS_PASSWORD}
export role_name=${role_name}
LOG_FILE="/var/log/startup_script.log"
sudo touch $LOG_FILE
sudo chmod 666 $LOG_FILE

# Redirect stdout and stderr to log file
exec >> "$LOG_FILE" 2>&1


echo "Starting script execution at $(date)"
sudo dnf install -y sshpass 
sudo dnf install -y rsyslog 

sudo systemctl enable rsyslog
sudo systemctl start rsyslog 

sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^UsePAM no/UsePAM yes/' /etc/ssh/sshd_config 
sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf 
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf 
sudo sed -i 's/^ssh_pwauth: false/ssh_pwauth: true/' /etc/cloud/cloud.cfg 
sleep 30
sudo cloud-init clean 
sudo cloud-init init 
sleep 60
sudo systemctl restart sshd 
sudo systemctl daemon-reload 

# Set the password for "ec2-user" (USE WITH CAUTION)
echo "${AWS_USER}:${AWS_PASSWORD}" | sudo chpasswd 
sleep 60

# install ansible 
sudo dnf install -y ansible-core 


ansible-pull -i localhost, -U https://github.com/manupanand-freelance-developer/aws-devops  k8s-infra-selfmanaged/ansible/playbook.yml  -e ansible_user=${AWS_USER} -e ansible_password=${AWS_PASSWORD} -e role_name=${role_name} 


