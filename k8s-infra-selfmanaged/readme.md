# Self-Managed Kubernetes Cluster

This project automates the deployment of a self-managed Kubernetes cluster using Terraform and Ansible. The cluster is created in a private AWS VPC and consists of control plane and worker nodes provisioned with `kubeadm`.

## Project Overview
- **Infrastructure as Code (IaC):** Uses Terraform to create AWS resources.
- **Configuration Management:** Automates Kubernetes setup with Ansible.
- **Networking:** Deploys the cluster in a private VPC with security groups.
- **Cluster Components:** Kubernetes control plane and worker nodes.
- **Container Networking:** Calico is used for networking (optional, needs manual setup).

## Prerequisites
- Terraform
- Ansible
- AWS CLI
- kubectl
- Ansible control node with SSH access to instances


# Kubernetes architecture

![Kubernetes architecture](https://github.com/manupanand-freelance-developer/aws-devops/blob/main/images/kube-archi.png)


## Deployment Steps
### 1. Provision AWS Resources
```sh
terraform init -backend-config=env-dev/state.tfvars
terraform plan -var-file=env-dev/main.tfvars
terraform apply  -var-file=env-dev/main.tfvars -auto-approve
```

### 2. Configure Kubernetes
Ansible will be configured using teraform

### 3. Join Worker Nodes
Worker nodes retrieve the join command from control plane using scp.


## Verification
Check if all nodes are ready:
```sh
kubectl get nodes
```
Check cluster pods:
```sh
kubectl get pods -A
```

## Cleanup
To delete all resources:
```sh
terraform destroy -var-file=env-dev/main.tfvars -auto-approve
```
# Using Hashicorp vault 
- configure the needed secrets for user and password, ami ..etc



## Future Improvements
- Automate Calico installation
- Enhance security with IAM roles and policies

---
This project provides a scalable, secure Kubernetes cluster with automation for provisioning and configuration. 🚀

