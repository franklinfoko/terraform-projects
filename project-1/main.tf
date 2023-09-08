provider "aws" {
  region     = "us-east-1"
  access_key = "PUT YOUR OWN"
  secret_key = "PUT YOUR OWN"
}

# 1. Create VPC
resource "aws_vpc" "vpc-1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-project"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "igw-1" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name = "igw-project-1"
  }
}

# 3. Create custom Route Table
resource "aws_route_table" "rt-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-1.id
  }

  tags = {
    Name = "rt-project-1"
  }
}

# 4. Create a subnet
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.vpc-1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-project"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "rt-association-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt-1.id
}

# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "sg-1" {
  name        = "franklin-sg"
  description = "Security Group to allow port 22, 80, 443"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg-project-1"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "ni-1" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg-1.id]

  tags = {
    Name = "ni-project-1"
  }
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "eip-1" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.ni-1.id
  associate_with_private_ip = "10.0.1.50"

  # Note: EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.igw-1]
}

# 9. Create Ubuntu Server and install/enable apache2
resource "aws_instance" "ec2-1" {
  ami               = "ami-053b0d53c279acc90" # Ubuntu Server 22.04 LTS
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "devops-foko"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ni-1.id
  }

  # Install and enable apache2 using user_date
  /* user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your web server is up ! > /var/www/html/index.html'
              sudo systemctl enable apache2
              EOF */


  # Install and enable apache2 remote provisioner
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./devops-foko.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install apache2 -y",
      "sudo ufw allow 'Apache'",
      "sudo systemctl enable apache2"
    ]
  }

  tags = {
    Name = "ec2-project-1"
  }
}

output "server_public_ip" {
  value = aws_eip.eip-1.public_ip
}

output "server_private_ip" {
  value = aws_instance.ec2-1.private_ip
}

output "server_id" {
  value = aws_eip.eip-1.id
}