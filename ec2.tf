#generate key pair in AWS to be used in EC2 instance
resource "aws_key_pair" "ec2key" {
  key_name   = "ec2key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCg95HNKzdCUI2sN2fyfY9MT0i70uRmE0UIzTUljJqhxg+yQeg7PfW+a3KBh5YgvedeE/Q4L9okTErCk4iRs8dE1DymQqaPsm66aH1zuU9zPNJlhEkn3hBOtr+f1uxZnlzOoI2xA7HImrtiM3eGCNGAetklTteAEkCpEuTBfy0QvxlxHajGpw75JxWKsyylgT2tc4RY8gqjLWiyqyAemAoc28ZLRAqtRuBj/zDPPBzU2+wwhaIW1Vyit5xnQA8SC7kScOunw5UxQl05suqkO/lp93l+n3RrjPJmpG+uYiDdeQrEDKfLWMyuu4Zmxm/EcxNwnSbeGXOMj86RJDDWpTECG/LwvpXv4H+7me5BNbgIUdV1xCruZoZLBGR04WogJQz3EqM3twjkw64QHhZu9u/k4DFh9dV3vdDhBkb8ztjzYvO0L157Re2JflxfZ22Yvr9TdexOjw2sYyi8oOWyn28dLko4bPNLu221ZlwQLKIMXfzSSjZ4g6STrvlbXaN3nJs= miguel@Miguels-MacBook-Air.local"
}

#create launch template to be used with ASG
resource "aws_launch_template" "nginxLaunchTemplate" {
  name = "nginxLaunchTemplate"
  image_id = "ami-0f844a9675b22ea32"
  instance_type = "t2.micro"
  iam_instance_profile {name = aws_iam_instance_profile.instance_profile.name}
  key_name = "ec2key"
#   vpc_security_group_ids = [aws_security_group.instance_sg.id]
  network_interfaces {
    subnet_id = aws_subnet.main.id
    associate_public_ip_address = "true"
    security_groups = [aws_security_group.instance_sg.id]
  }
  user_data = filebase64("setup.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.instance_name
    }
  }
}

#create ASG with 2 AZ for resiliency
resource "aws_autoscaling_group" "nginxASG" {
  name                      = "nginx-asg"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_template {
    name = aws_launch_template.nginxLaunchTemplate.name
    version = "${aws_launch_template.nginxLaunchTemplate.latest_version}"
  }
  target_group_arns = [aws_lb_target_group.nginx_alb.arn]
#   instance_refresh {
#     strategy = "Rolling"
#     triggers = ["launch_template"]
#   }
  vpc_zone_identifier       = [aws_subnet.main.id, aws_subnet.secondary.id]

  tag {
    key                 = "name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
}

#create target group
resource "aws_lb_target_group" "nginx_alb" {
  name        = "nginxALB"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

#attach target group to ASG
# resource "aws_autoscaling_attachment" "nginxASG" {
#   autoscaling_group_name = aws_autoscaling_group.nginxASG.id
#   lb_target_group_arn    = aws_lb_target_group.nginx_alb.arn
# }

#ALB for sending requests target group
resource "aws_lb" "loadbalancer" {
  name               = "lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.main.id,aws_subnet.secondary.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.assessment-bucket.id
    prefix  = "lb-access-logs"
    enabled = true
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_alb.arn
  }
}

#route requests from ALB to target group
# resource "aws_lb_listener_rule" "static" {
#   listener_arn = aws_lb_listener.loadbalancer.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.nginx_alb.arn
#   }

#   condition {
#     path_pattern {
#       values = ["*"]
#     }
#   }
# }

# resource "aws_instance" "app_server" {
# #   ami                  = "ami-0f844a9675b22ea32"
# #   instance_type        = "t2.micro"
# #   iam_instance_profile = aws_iam_instance_profile.instance_profile.name
# #   subnet_id = aws_subnet.main.id
# #   key_name = "ec2key"
# #   security_groups = [aws_security_group.instance_sg.id]
# #   vpc_security_group_ids = [aws_security_group.instance_sg.id]
# #   associate_public_ip_address = "true"
# #   user_data = file("setup.sh")

#   tags = {
#     Name = var.instance_name
#   }
# }

#security group for ALB
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id
  name = "loadbalancerSG"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.main.cidr_block,aws_subnet.secondary.cidr_block]
  }

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.main.cidr_block,aws_subnet.secondary.cidr_block]
  }
}

#security group for instances
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id
  name = "InstanceSG"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

#   ingress {
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   ingress {
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

# temporarily allow ssh for testing
#   ingress {
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

