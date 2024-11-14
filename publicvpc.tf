# Create the new VPC
resource "aws_vpc" "publicvpc" {
  cidr_block = "11.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "publicvpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.publicvpc.id
  tags = {
    Name = "public-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.publicvpc.id
  cidr_block              = "11.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.publicvpc.id
}

# Create a route to the Internet Gateway for the public subnet
resource "aws_route" "internet_route_vpc2" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_igw.id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Create an EC2 Key Pair (replace with your key pair or use an existing one)
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-ec2-key"
  public_key = file("~/.ssh/id_rsa.pub") # Use your local public key file
}
# Create Security Group for RDS
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-security-group"
  description = "Allow internal access to frontend security groups"
  vpc_id = aws_vpc.publicvpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow from any IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Launch an EC2 instance in the public subnet with user data script
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0984f4b9e98be44bf" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2-public-frontend"
  }
  depends_on = [
    aws_db_instance.rds,
    aws_secretsmanager_secret_version.rds_secret_version,
    aws_instance.ec2_private
  ]
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  # Optional: add user data for EC2 initialization
  user_data = file("userdatafrontend.sh")
}
