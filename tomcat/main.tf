locals {
  environment_name = "${terraform.workspace}" 
}

resource "aws_security_group" "tomcat-sg" {
  name        = "allow_tl"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.mvpc_id

  ingress {
    description = "admin to ssh"
    from_port   = 22
    to_port     = 22 
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    description = "End-user to tomcat"
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
    Name = "${local.environment_name}-tomcat_sg"
  }
}

resource "aws_instance" "tomcat" {
  ami                    = "ami-0f15e0a4c8d3ee5fe"
  instance_type          = var.minstance_type
  subnet_id              = var.mpublic_subnet
  vpc_security_group_ids = [aws_security_group.tomcat-sg.id]
  key_name               = var.mkey_name
  user_data              = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install java-openjdk11 -y
cd /opt
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.70/bin/apache-tomcat-9.0.70-windows-x64.zip
unzip apache-tomcat-9.0.70-windows-x64.zip
mv apache-tomcat-9.0.70 tomcat9
rm -fr apache-tomcat-9.0.70-windows-x64.zip
cd tomcat9/
cd bin
chmod 755 *.sh
./startup.sh
# cd /tmp
# wget https://www.oracle.com/webfolder/technetwork/tutorials/obe/fmw/wls/10g/r3/cluster/session_state/files/shoppingcart.zip
# unzip shoppingcart.zip
# cp shoppingcart.war /opt/tomcat9/webapps

EOF  

  tags = {
    Name = "${local.environment_name}-tomcat"
  }
}