locals {
  environment_name = "${terraform.workspace}" 
}

resource "aws_security_group" "alb" {
  name        = "allow enduser"
  description = "Allow enduser inbound traffic"
  vpc_id      = var.mvpc_id

  ingress {
    description = "enduser for admin"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
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
      Name        = "${local.environment_name}-Alb-sg"
    }
}


# alb 

resource "aws_lb" "alb" {
  name               = "${local.environment_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnets

  enable_deletion_protection = false

  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.bucket
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = {
      Name        = "${local.environment_name}-Alb"
    }
}

#tg 
resource "aws_lb_target_group" "tomcat" {
  name     = "Tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id      = var.mvpc_id

  # health_check {
  #   path                = "/"
  #   port                = 80
  #   healthy_threshold   = 6
  #   unhealthy_threshold = 2
  #   timeout             = 2
  #   interval            = 5
  #   matcher             = "200" # has to be HTTP 200 or fails
  # }
}

#listener 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat.arn
  }
}

resource "aws_lb_target_group_attachment" "tomcat" {
  target_group_arn = aws_lb_target_group.tomcat.arn
  target_id        = var.tomcat_instance_id
  port             = 8080
}

resource "aws_lb_target_group" "jenkins" {
  name     = "Tg-2"
  port     = 80
  protocol = "HTTP"
  vpc_id      = var.mvpc_id

  # health_check {
  #   path                = "/jenkins"
  #   port                = 80
  #   healthy_threshold   = 6
  #   unhealthy_threshold = 2
  #   timeout             = 2
  #   interval            = 5
  #   matcher             = "200" # has to be HTTP 200 or fails
  # }
}
resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = var.jenkins_instance_id
  port             = 8080
}
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  condition {
    host_header {
      values = ["jenkins.com"]
    }
  }
}
resource "aws_lb_target_group" "sonarqube" {
  name     = "Tg-3"
  port     = 80
  protocol = "HTTP"
  vpc_id      = var.mvpc_id
}
resource "aws_lb_target_group_attachment" "sonarqube" {
  target_group_arn = aws_lb_target_group.sonarqube.arn
  target_id        = var.sonarqube_instance_id
  port             = 9000
}
resource "aws_lb_listener_rule" "sonarqube" {
  listener_arn = aws_lb_listener.http.arn
  # priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }

  condition {
    host_header {
      values = ["sonar-bab.com"]
    }
  }
}