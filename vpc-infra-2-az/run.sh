# Terraform init
 echo "Initializing terraform"
 terraform init -backend-config=env-dev/state.tfvars
 #terraform plan
 echo "terraform plan"
 terraform plan -var-file=env-dev/main.tfvars
 # terrform apply 
 echo "terraform apply"
 terraform apply -var-file=env-dev/main.tfvars -auto-approve
