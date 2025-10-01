
# control-plane resource

resource "aws_instance" "instance_control_plane" {
    depends_on               = [ aws_iam_instance_profile.iam_instance_profile]
    
    instance_type            = var.instance_type
    ami                      = var.aws_ami_id
    subnet_id                = var.kube_subnet_id  
    iam_instance_profile     = aws_iam_instance_profile.iam_instance_profile.name
    vpc_security_group_ids   = [var.private_security_group_id] 

    #instance option
    instance_market_options {
      market_type            = "spot"
      spot_options {
        instance_interruption_behavior      = "stop"
        spot_instance_type                  ="persistent" 
      } 
    } 
    #volume
    root_block_device {
        volume_size           =var.volume_size 
    }  
    #user data commands
    user_data = base64encode(templatefile("${path.module}/control-plane.sh",{
        AWS_USER     = var.aws_user
        AWS_PASSWORD = var.aws_password
        role_name    = "control-plane"
     }))
    # Wait for user data script to complete and create join.sh file
    provisioner "remote-exec" {
      inline = [
        "echo 'Waiting for user data script to complete...'",
        "while [ ! -e /tmp/join.sh ]; do echo 'Waiting for join.sh...'; sleep 30; done",
        "echo 'join.sh file found, waiting for Kubernetes to be ready...'",
        "sleep 60",
        "echo 'Control plane setup completed'"
      ]
      
      connection {
        type     = "ssh" 
        user     = var.aws_user
        password = var.aws_password
        host     = self.private_ip
        timeout  = "10m"
        # SSH through bastion to private instance
        bastion_host = var.bastion_public_ip
        bastion_user = var.aws_user
        bastion_password = var.aws_password
      }
    }

    tags={
        Name="${var.name}-${var.env}-instance"
    }
  
}
