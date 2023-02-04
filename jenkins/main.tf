# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }

locals {
  environment_name = "${terraform.workspace}" 
}

resource "aws_security_group" "cicd" {
  name        = "allow_admin"
  description = "Allow admin via ssh"
  vpc_id      = var.mvpc_id

  ingress {
    description = "SSH from Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "For admin"
    from_port   = 8080
    to_port     = 8080
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
    Name      = "${local.environment_name}-cicd-sg",
    Terraform = "true"
  }
}

resource "aws_instance" "cicd" {
  ami           = "ami-0f15e0a4c8d3ee5fe"
  instance_type = var.minstance_type
  subnet_id              = var.mpublic_subnet
  vpc_security_group_ids = [aws_security_group.cicd.id]
  key_name               = var.mkey_name
  user_data              = <<-EOF
              #!/bin/bash
              wget -O /etc/yum.repos.d/jenkins.repo \
              https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum update -y
              amazon-linux-extras install java-openjdk11
              yum install jenkins -y
              systemctl start jenkins
              EOF

  tags = {
    Name = "${local.environment_name}-cicd"
  }
}



