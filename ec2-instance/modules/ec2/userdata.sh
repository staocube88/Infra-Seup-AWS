
#!/bin/bash

# Define log file
export AWS_USER=$TF_VAR_aws_user
export AWS_PASSWORD=$TF_VAR_aws_password
export role_name=$TF_VAR_role_name
LOG_FILE="/var/log/startup_script.log"
sudo touch $LOG_FILE
sudo chmod 666 $LOG_FILE

# Redirect stdout and stderr to log file


echo "Starting script execution at $(date)"
sudo dnf install -y sshpass | tee -a /var/log/startup_script.log
sudo dnf install -y rsyslog | tee -a /var/log/startup_script.log

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
sudo cloud-init clean | tee -a /var/log/startup_script.log
sudo cloud-init init | tee -a /var/log/startup_script.log
sleep 60
sudo systemctl restart sshd | tee -a /var/log/startup_script.log
sudo systemctl daemon-reload | tee -a /var/log/startup_script.log

# Set the password for "ec2-user" (USE WITH CAUTION)
echo "${AWS_USER}:${AWS_PASSWORD}" | sudo chpasswd  | tee -a /var/log/startup_script.log
sleep 60

# install ansible 
sudo dnf install -y ansible-core | tee -a /var/log/startup_script.log


ansible-pull -i localhost, -U https://github.com/manupanand-freelance-developer/aws-devops.git  ec2-instance/ansible/playbook.yml  -e ansible_user=${AWS_USER} -e ansible_password=${AWS_PASSWORD} -e role_name=${role_name} | tee -a /var/log/startup_script.log

