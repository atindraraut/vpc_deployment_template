# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gateway"
  }
}

# Create a public subnet (for NAT Gateway and one EC2 instance)
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create private subnet for EC2 and RDS
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet"
  }
}
# Create private subnet to maintain the acvailiblity
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private2-subnet"
  }
}

# Create NAT Gateway in public subnet
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "main-nat-gateway"
  }
}
# Update the main route table to add a route to the Internet Gateway
resource "aws_route" "internet_route" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}
# Route Table for Private Subnet to use NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw.id
}

# EC2 Instance in Public Subnet
resource "aws_instance" "ec2_public" {
  ami           = "ami-0866a3c8686eaeeba" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2-public-backend"
  }
  depends_on = [
    aws_db_instance.rds,
    aws_secretsmanager_secret_version.rds_secret_version,
    aws_instance.ec2_private
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name      = "awsterraformtutorial"
  private_ip = "10.0.1.12"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  # Optional: add user data for EC2 initialization
  user_data = file("userdatabackend.sh")
}

# Create RDS instance in private subnet
resource "aws_db_instance" "rds" {
  identifier        = "my-rds-instance"
  engine            = "mysql"
  engine_version    = "8.0" # Change based on your preference (mysql, postgres, etc.)
  instance_class    = "db.t3.micro"
  allocated_storage = 10
  db_name           = "testdb"
  username          = "admin"
  password          = "Password123"  # You will store this in Secrets Manager later
  skip_final_snapshot = true
  multi_az          = false
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-instance"
  }

  # Store RDS credentials in Secrets Manager
  lifecycle {
    create_before_destroy = true
  }
}

# RDS Subnet Group (for private subnets)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "my-rds-subnet-group"
  subnet_ids = [aws_subnet.private.id,aws_subnet.private2.id]

  tags = {
    Name = "my-rds-subnet-group"
  }
}

# Create Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow internal access to RDS"
  vpc_id = aws_vpc.main.id
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

# Create Secrets Manager secret for RDS credentials in custom JSON format
resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "db-creds-secret2"
  description = "RDS credentials stored in Secrets Manager"
  recovery_window_in_days  = 0
}

# Push RDS credentials to Secrets Manager in custom JSON format
resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    DB_USER = "admin",
    DB_PASSWORD = "Password123",  # Should match the password in RDS
    DB_HOST     = aws_db_instance.rds.endpoint,  # Reference RDS endpoint dynamically
    DB_PORT     = "3306",
    DB_NAME = "testdb"
  })
}

# Output the RDS credentials secret ARN
output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_secret.arn
}

