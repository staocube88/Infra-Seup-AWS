resource "aws_security_group" "kube_control_plane" {
    description = "Security group for control plane"
    name        =  "kube-control-plane-sg"
    vpc_id      =   data.aws_vpc.private_vpc.id 
  

#ssh port
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks  =["0.0.0.0/0"] #cidr of default vpc
    }

# kube main ports
  dynamic "ingress" {
    for_each = var.cp_ingress
    content {
      from_port     = tonumber(split("-",ingress.value.port)[0])
      to_port       = tonumber(split("-",ingress.value.port)[length(split("-",ingress.value.port))-1])
      protocol      = "TCP"
      cidr_blocks   = [tostring(data.aws_subnet.kube_subnet.cidr_block) ]#var.kube_subnet_cidr data.aws_subnet.kube_subnet.cidr_block
    }
  }
  #udp ingress
   dynamic "ingress" {
    for_each = var.cp_udp_ingress
    content {
      from_port     = tonumber(split("-",ingress.value.port)[0])
      to_port       = tonumber(split("-",ingress.value.port)[length(split("-",ingress.value.port))-1])
      protocol      = "UDP"
      cidr_blocks   = [tostring(data.aws_subnet.kube_subnet.cidr_block) ]#var.kube_subnet_cidr data.aws_subnet.kube_subnet.cidr_block
    }
  }
# dynamic egress
    dynamic "egress" {
    for_each = var.cp_egress
    content {
        from_port     = tonumber(split("-",egress.value.port)[0])
        to_port       = tonumber(split("-",egress.value.port)[length(split("-",egress.value.port))-1])
        protocol    = "TCP"
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
    }
    }
    #udp egress
    dynamic "egress" {
    for_each = var.cp_udp_egress
    content {
        from_port     = tonumber(split("-",egress.value.port)[0])
        to_port       = tonumber(split("-",egress.value.port)[length(split("-",egress.value.port))-1])
        protocol    = "UDP"
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
    }
    }
    # internet
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }


    tags={
        Name= "kube-control-plane-sg"
    }
}
# TCP	Inbound	6443	    Kubernetes API server	    All
# TCP	Inbound	2379-2380	etcd server client API	    kube-apiserver, etcd
# TCP	Inbound	10250	    Kubelet API	                Self, Control plane
# TCP	Inbound	10259	    kube-scheduler	            Self
# TCP	Inbound	10257	    kube-controller-manager	    Self

resource "aws_security_group" "kube_worker" {
    description = "Security group for worker"
    name        =  "kube-worker-sg"
    vpc_id      =   data.aws_vpc.private_vpc.id 
  

#ssh port
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks  =["0.0.0.0/0"] #cidr od fefault vpc
    }

    # ingress 
    dynamic "ingress" {
      for_each = var.worker_ingress
      content {
       from_port     = tonumber(split("-",ingress.value.port)[0])
       to_port       = tonumber(split("-",ingress.value.port)[length(split("-",ingress.value.port))-1])
        protocol    = "TCP"
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
      }
    }
    #udp_ingress
       dynamic "ingress" {
      for_each = var.worker_udp_ingress
      content {
       from_port     = tonumber(split("-",ingress.value.port)[0])
       to_port       = tonumber(split("-",ingress.value.port)[length(split("-",ingress.value.port))-1])
        protocol    = "UDP"
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
      }
    }
    #egress
    dynamic "egress" {
      for_each = var.worker_egress 
      content {
        from_port     = tonumber(split("-",egress.value.port)[0])
        to_port       = tonumber(split("-",egress.value.port)[length(split("-",egress.value.port))-1])
        protocol    = "TCP" 
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
      }
    }
    #udp egress
      dynamic "egress" {
      for_each = var.worker_udp_egress 
      content {
        from_port     = tonumber(split("-",egress.value.port)[0])
        to_port       = tonumber(split("-",egress.value.port)[length(split("-",egress.value.port))-1])
        protocol    = "UDP" 
        cidr_blocks = [tostring(data.aws_subnet.kube_subnet.cidr_block)] 
      }
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags={
        Name="kube-worker-sg"
    }

}
# TCP	Inbound	10250	    Kubelet API	                Self, Control plane
# TCP	Inbound	10256	    kube-proxy	                Self, Load balancers
# TCP	Inbound	30000-32767	NodePort Services†	        All


# allow security groups to communicate 
# attach each port with security group

resource "aws_vpc_security_group_ingress_rule" "general_control_plane_from_worker" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]
   
 
  from_port                     =  6443
  to_port                       = 65535
  ip_protocol                   = "TCP"
  security_group_id             = aws_security_group.kube_worker.id# the initiater worker
  referenced_security_group_id  = aws_security_group.kube_control_plane.id#destinaton security group control plane
}
resource "aws_vpc_security_group_ingress_rule" "general_worker_from_control_plane" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]
 
  from_port                     =  6443
  to_port                       = 10260
  ip_protocol                   = "TCP"
  security_group_id             = aws_security_group.kube_control_plane.id# the initiater worker
  referenced_security_group_id  = aws_security_group.kube_worker.id#destinaton security group control plane
}

# enabling Ip in IP protocol 4 for Calico network


resource "aws_vpc_security_group_ingress_rule" "control_plane_from_worker" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]

   description = "IP in IP protocol 4"
   
 
  ip_protocol                   = "4"
  security_group_id             = aws_security_group.kube_worker.id# the initiater worker
  referenced_security_group_id  = aws_security_group.kube_control_plane.id#destinaton security group control plane
}
resource "aws_vpc_security_group_egress_rule" "control_plane_to_worker" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]

   description = "IP in IP protocol 4"
   

  ip_protocol                   = "4"
  security_group_id             = aws_security_group.kube_control_plane.id# the initiater worker
  referenced_security_group_id  = aws_security_group.kube_worker.id#destinaton security group control plane
}


resource "aws_vpc_security_group_ingress_rule" "worker_from_control_plane" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]

   description = "IP in IP protocol 4"

  ip_protocol                   = "4"
  security_group_id             = aws_security_group.kube_control_plane.id# the initiater worker whonsend 
  referenced_security_group_id  = aws_security_group.kube_worker.id#destinaton security group control plane
}
resource "aws_vpc_security_group_egress_rule" "worker_to_control_plane" {
   depends_on = [ aws_security_group.kube_control_plane, aws_security_group.kube_worker ]

   description = "IP in IP protocol 4"

  ip_protocol                   = "4"
  security_group_id             = aws_security_group.kube_worker.id# the initiater worker
  referenced_security_group_id  = aws_security_group.kube_control_plane.id#destinaton security group control plane
}