provider "aws" { 
  region     = "ap-south-1" 
 
 
} 
 
 
data "aws_availability_zones" "available" { 
  state = "available" 
} 
 
resource "aws_vpc" "this" { 
  cidr_block           = "10.0.0.0/16" 
  enable_dns_hostnames = true 
  enable_dns_support   = true 
} 
 
resource "aws_subnet" "public" { 
  count = 3 
 
  vpc_id            = aws_vpc.this.id 
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index) 
  availability_zone = data.aws_availability_zones.available.names[count.index] 
 
  map_public_ip_on_launch = true 
} 
 
resource "aws_internet_gateway" "this" { 
  vpc_id = aws_vpc.this.id 
} 
 
resource "aws_route_table" "main" { 
  vpc_id = aws_vpc.this.id 
 
  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.this.id 
  } 
} 
 
resource "aws_route_table_association" "internet_access" { 
  count = 3 
 
  subnet_id      = aws_subnet.public[count.index].id 
  route_table_id = aws_route_table.main.id 
} 
 
resource "aws_security_group" "app_sg" { 
  name   = "Public-sg" 
  vpc_id = aws_vpc.this.id 
 
  ingress { 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  ingress { 
    from_port   = 80 
    to_port     = 80 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  ingress { 
    from_port   = 443 
    to_port     = 443 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  tags = { 
    Name = "app-sg" 
  } 
} 
 
resource "aws_instance" "app_instance" { 
  ami                    = "ami-0287a05f0ef0e9d9a" 
  instance_type          = "t2.micro" 
  key_name               = "infra-key" 
  subnet_id              = aws_subnet.public[0].id 
  vpc_security_group_ids = [aws_security_group.app_sg.id] 
  user_data              = <<-EOF 
              #!/bin/bash 
              sudo apt-get update 
              sudo apt-get install -y nginx 
              EOF 
  associate_public_ip_address = true 
  tags = { 
    Name = "app-infra" 
  } 
}
