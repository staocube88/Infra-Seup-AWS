# create vpc for kubernetes cluster 
resource "aws_vpc" "private" {

    cidr_block = var.cidr_block


    tags = {
      Name ="${var.env}-private-vpc"
    }
  
}

# peering connection
resource "aws_vpc_peering_connection" "default_private_peering" {
  peer_vpc_id  =  var.default_vpc_id 
  vpc_id       =  aws_vpc.private.id
  auto_accept  =  true  


  tags={
    Name ="${var.env}-private-vpc-peering connection"
  } 

}

# add route to default vpc- adding the routes of 

resource "aws_route" "default_vpc_rt" {
  route_table_id            = var.default_vpc_rt
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default_private_peering.id 
}