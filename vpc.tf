data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "172.32.0.0/16"
}

#create /24 subnet for assessment criteria
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.32.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Main"
  }
}

#secondary subnet for resiliency
resource "aws_subnet" "secondary" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.32.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Secondary"
  }
}

#allow access from internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

#create route to internet
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main"
  }
}

#associate the previous route table to the subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.secondary.id
  route_table_id = aws_route_table.main.id
}