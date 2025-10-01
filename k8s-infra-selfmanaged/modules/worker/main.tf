

# worker resource 
resource "aws_instance" "instance_worker_node_1" {
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
    user_data = base64encode(templatefile("${path.module}/worker.sh",{
        AWS_USER     = var.aws_user
        AWS_PASSWORD = var.aws_password
        role_name    = "worker-node"
        remote_ip    = var.remote_ip
        node_name         = var.name
     }))
    tags={
        Name="${var.name}-${var.env}-instance"
    }
  
}