resource "aws_internet_gateway" "private_vpc_igw" {
        vpc_id = aws_vpc.private.id
         
         tags={
            Name ="${var.env}-vpc-igw"
         }
}