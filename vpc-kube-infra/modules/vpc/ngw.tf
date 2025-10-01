# eastic ip 
 resource "aws_eip" "private_vpc_nat_ip" {
   domain ="vpc"
 }


# nat gate way
resource "aws_nat_gateway" "public_subnet_ntgw" {
  allocation_id     =  aws_eip.private_vpc_nat_ip.id 
  subnet_id         =  aws_subnet.public_subnets.id 

  tags={
    Name="${var.env}-public-subnet-ntgw"
  } 
}