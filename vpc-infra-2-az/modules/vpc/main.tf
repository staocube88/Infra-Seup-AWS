# main private vpc
resource "aws_vpc" "private" {
  cidr_block = var.cidr

  tags = {
    Name= "${var.env}-vpc-private"
  }
}

# then we need to connect vpc default with our vpc through peering conection
#update all route tables also
# and also route table in default vpc
resource "aws_vpc_peering_connection" "peer-conn" {

  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.private.id
 
  # but we need to approve
  auto_accept   = true 
  tags = {
    Name = "${var.env}-vpc-peeing-connection"
  }
  # need to allow peering connection in route tables
  # and also add routes of private to default
}
# adding routes from private to exixting default
resource "aws_route" "peer-route-default-vpc" {
  route_table_id            =  var.default_vpc_rt #default vpc cidr
  destination_cidr_block    =  var.cidr           #private vpc cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-conn.id 
}

# subnet for private vpc
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.private.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name= "${var.env}-public-sbnt-vpc-prvt-${var.availability_zones[count.index]}"
  }
}
resource "aws_subnet" "web_subnets" {
  count             = length(var.web_subnets)
  vpc_id            = aws_vpc.private.id
  cidr_block        = var.web_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name= "${var.env}-web-sbnt-vpc-prvt-${var.availability_zones[count.index]}"
  }
}
resource "aws_subnet" "app_subnets" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.private.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name="${var.env}-app-sbnt-vpc-prvt-${var.availability_zones[count.index]}"
  }
}
resource "aws_subnet" "db_subnets" {
  count             = length(var.db_subnets)
  vpc_id            = aws_vpc.private.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]# will create db_subnet for  each az

  tags = {
    Name= "${var.env}-db-sbnt-vpc-prvt-${var.availability_zones[count.index]}"
  }
}

# route table
resource "aws_route_table" "public_subnets-rt" {
    count           = length(var.public_subnets)
    vpc_id          = aws_vpc.private.id 

    #add igw rt
    route{
      cidr_block =  "0.0.0.0/0"
      gateway_id = aws_internet_gateway.pub-sub-igw.id
    }
    #add peering connection
    route{
      cidr_block                = var.default_vpc_cidr 
      vpc_peering_connection_id = aws_vpc_peering_connection.peer-conn.id
    }

    tags={
        Name="${var.env}-public-sbnt-rt-${var.availability_zones[count.index]}"
    }

}
resource "aws_route_table" "app_subnets-rt" {
    count           = length(var.app_subnets)
    vpc_id          = aws_vpc.private.id 

      #add nat gateway
    route{
      cidr_block =  "0.0.0.0/0"
      nat_gateway_id =  aws_nat_gateway.ntgw-public.*.id[count.index]
    }
    #add peering connection
    route{
      cidr_block                = var.default_vpc_cidr 
      vpc_peering_connection_id = aws_vpc_peering_connection.peer-conn.id
    }


    tags={
        Name="${var.env}-app-sbnt-rt-${var.availability_zones[count.index]}"
    }

}
resource "aws_route_table" "web_subnets-rt" {
    count           = length(var.web_subnets)
    vpc_id          = aws_vpc.private.id 

    #add nat gateway
    route{
      cidr_block =  "0.0.0.0/0"
      nat_gateway_id =  aws_nat_gateway.ntgw-public.*.id[count.index]
    }
    #add peering connection
    route{
      cidr_block                = var.default_vpc_cidr 
      vpc_peering_connection_id = aws_vpc_peering_connection.peer-conn.id
    }

    tags={
        Name="${var.env}-web-sbnt-rt-${var.availability_zones[count.index]}"
    }

}
resource "aws_route_table" "db_subnets-rt" {
    count           = length(var.db_subnets)
    vpc_id          = aws_vpc.private.id 

    #add nat gateway
    route{
      cidr_block =  "0.0.0.0/0"
      nat_gateway_id =  aws_nat_gateway.ntgw-public.*.id[count.index]
    }
    #add peering connection
    route{
      cidr_block                = var.default_vpc_cidr 
      vpc_peering_connection_id = aws_vpc_peering_connection.peer-conn.id
    }

    tags={
        Name="${var.env}-db-sbnt-rt-${var.availability_zones[count.index]}"
    }

}
# need to attach rout tables to subnets-association
resource "aws_route_table_association" "public-rt-asso" {
  count             = length(var.public_subnets)
  subnet_id         = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_subnets-rt.*.id[count.index] 

}
resource "aws_route_table_association" "web-rt-asso" {
  count             = length(var.web_subnets)
  subnet_id         = aws_subnet.web_subnets.*.id[count.index]
  route_table_id = aws_route_table.web_subnets-rt.*.id[count.index] 

}
resource "aws_route_table_association" "app-rt-asso" {
  count             = length(var.app_subnets)
  subnet_id         = aws_subnet.app_subnets.*.id[count.index]
  route_table_id = aws_route_table.app_subnets-rt.*.id[count.index] 

}
resource "aws_route_table_association" "db-rt-asso" {
  count             = length(var.db_subnets)
  subnet_id         = aws_subnet.db_subnets.*.id[count.index]
  route_table_id = aws_route_table.db_subnets-rt.*.id[count.index] 

}
# internet gateway attach to public subnet
resource "aws_internet_gateway" "pub-sub-igw"{
  vpc_id =  aws_vpc.private.id

  tags={
    Name= "${var.env}-pub-sub-ig"
  }
}

# nat gateway for wach availability zones
#nat-gw need ip for attaching- elastic ip
resource "aws_eip" "eip-public" {
  count     = length(var.availability_zones)
  domain    = "vpc"
}
resource "aws_nat_gateway" "ntgw-public" {
  count             = length(var.availability_zones)
  allocation_id     = aws_eip.eip-public.*.id[count.index]
  subnet_id         = aws_subnet.public_subnets.*.id[count.index] 

tags={
  Name="${var.env}-ntgw-pblic-${var.availability_zones[count.index]}"
}
  
}
# this nat gate way should be add for all other subnets route- table


