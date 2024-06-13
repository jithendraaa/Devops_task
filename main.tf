provider "aws" {
  region = "us-east-1"
}

# VPC Creation
resource "aws_vpc" "task_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TASK-VPC"
  }
}

# Public Subnet for the Jump Server
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.task_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

# Private Subnet for Web and DB Servers
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.task_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.task_vpc.id
  tags = {
    Name = "InternetGateway"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.task_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Web and DB Servers (Private Subnet)
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.task_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateSG"
  }
}

# Security Group for Jump Server (Public Subnet)
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.task_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "PublicSG"
  }
}

# EC2 Instance for Web Server
resource "aws_instance" "web" {
  ami             = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.private_sg.name]

  tags = {
    Name = "WebServer"
  }
}

# EC2 Instance for DB Server
resource "aws_instance" "db" {
  ami             = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.private_sg.name]

  tags = {
    Name = "DBServer"
  }
}

# EC2 Instance for Jump Server
resource "aws_instance" "jump_server" {
  ami             = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.public_sg.name]

  tags = {
    Name = "JumpServer"
  }
}
