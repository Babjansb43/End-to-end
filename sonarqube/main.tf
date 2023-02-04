locals {
  environment_name = "${terraform.workspace}" 
}

resource "aws_security_group" "sonar-sg" {
  name        = "Sonarqube"
  description = "Sonarqube"
  vpc_id      = var.mvpc_id

  ingress {
    description = "Admin to SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description     = "admin to sonarqube"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "jenkins to sonarqube"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
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
    Name      = "${local.environment_name}-sonar-sg",
    Terraform = "true"
  }
}


resource "aws_instance" "sonarqube" {
  ami           = "ami-0f15e0a4c8d3ee5fe"
  instance_type = var.sonar_instance_type
  subnet_id              = var.mpublic_subnet
  vpc_security_group_ids = [aws_security_group.sonar-sg.id]
  key_name               = var.mkey_name
  user_data              = <<-EOF
             #!/bin/bash
             amazon-linux-extras install java-openjdk11 -y
             cd /opt
             wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.10.61524.zip
             unzip sonarqube-8.9.10.61524.zip
             mv sonarqube-8.9.10.61524 sonarqube
             chmod 775 -R sonarqube
             useradd sonaradmin
             chown -R sonaradmin:sonaradmin /opt/sonarqube
             sudo su -c '/opt/sonarqube/bin/linux-x86-64/sonar.sh start' sonaradmin
              EOF
         
  tags = {
    Name = "${local.environment_name}-sonarqube"
  }
}