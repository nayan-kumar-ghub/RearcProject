provider "aws" {
  region = "us-east-1"
}

# VPC Creation
resource "aws_vpc" "quest_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "QuestAppVPC"
  }
}

# Public Subnet
resource "aws_subnet" "quest_public_subnet" {
  vpc_id                  = aws_vpc.quest_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "QuestPublicSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "quest_igw" {
  vpc_id = aws_vpc.quest_vpc.id

  tags = {
    Name = "QuestAppIGW"
  }
}

# Route Table
resource "aws_route_table" "quest_route_table" {
  vpc_id = aws_vpc.quest_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.quest_igw.id
  }

  tags = {
    Name = "QuestAppRouteTable"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "quest_route_association" {
  subnet_id      = aws_subnet.quest_public_subnet.id
  route_table_id = aws_route_table.quest_route_table.id
}

# Security Group
resource "aws_security_group" "quest_sg" {
  vpc_id      = aws_vpc.quest_vpc.id
  name        = "quest_app_sg"
  description = "Allow Node.js app and SSH access"

  # Allow HTTP access to Node.js app
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allocate Elastic IP
resource "aws_eip" "quest_eip" {
  domain = "vpc"

  tags = {
    Name = "QuestAppEIP"
  }
}

# Generate an SSH key pair dynamically
resource "tls_private_key" "quest_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Use the generated key for EC2 instance
resource "aws_key_pair" "generated_key" {
  key_name   = "quest_key"
  public_key = tls_private_key.quest_key.public_key_openssh
}

# EC2 Instance
resource "aws_instance" "quest_app" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  availability_zone      = "us-east-1a"
  subnet_id              = aws_subnet.quest_public_subnet.id
  vpc_security_group_ids = [aws_security_group.quest_sg.id]

  tags = {
    Name  = "QuestAppServer"
    Owner = "NK"
  }
}

# Associate Elastic IP with EC2 Instance
resource "aws_eip_association" "quest_eip_assoc" {
  instance_id   = aws_instance.quest_app.id
  allocation_id = aws_eip.quest_eip.id
}

# Null resource for file transfers and remote execution
resource "null_resource" "quest_app" {
  depends_on = [aws_instance.quest_app, aws_eip.quest_eip, aws_eip_association.quest_eip_assoc]

  # Define the connection block
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.quest_key.private_key_pem
    host        = aws_eip.quest_eip.public_ip
    timeout     = "5m"
  }

  # Wait for the instance to be ready before executing further commands
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for instance to be ready...'",
      "sleep 60",
      "echo 'Host *' | sudo tee -a /etc/ssh/ssh_config",
      "echo 'StrictHostKeyChecking no' | sudo tee -a /etc/ssh/ssh_config"
    ]
  }

  # Copy the QuestApp source directory to EC2
  provisioner "file" {
    source      = "./quest_app"
    destination = "/home/ubuntu/app"
  }

  # Copy installation script to EC2
  provisioner "file" {
    source      = "questapp_install.sh"
    destination = "/home/ubuntu/questapp_install.sh"
  }

  # Run the installation script on EC2
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ubuntu/questapp_install.sh",
      "sudo /home/ubuntu/questapp_install.sh"
    ]
  }
}

# Output the Public IP
output "ec2_public_ip" {
  value       = aws_eip.quest_eip.public_ip
  description = "Public IP of the EC2 instance"
}

# Deployment complete message
output "app_deployment_info" {
  value = join("", [
    "Your app is now deployed on instance: ", aws_instance.quest_app.id, "\n",
    "You can now browse/validate using: http://", aws_eip.quest_eip.public_ip, ":3000/"
  ])
}