resource "aws_ecs_cluster" "cluster" {
  name = var.clustername
}

resource "aws_ecs_task_definition" "task" {
  family                   = "designer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name" : "nginx",
      "image" : "public.ecr.aws/nginx/nginx:stable",
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ]
    }
  ])
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-05bb20e5204f2c6b4"

  ingress {
    from_port   = 8444
    to_port     = 8444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "web-ui"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["subnet-0423a1b05695ac070", "subnet-0b9e3ce12a1c5ae9f"]
  security_groups    = [aws_security_group.lb_sg.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "8444"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:782823230069:certificate/05ee3dfa-6e0d-41cc-b927-9987b150c021"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.group.arn
  }
}

resource "aws_security_group" "fargate_sg" {
  name        = "fargate_sg"
  description = "Allow inbound traffic"
  vpc_id      = "vpc-05bb20e5204f2c6b4"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "service" {
  name            = "nginx"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.fargate_sg.id]
    subnets          = ["subnet-0423a1b05695ac070", "subnet-0b9e3ce12a1c5ae9f"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.group.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

resource "aws_lb_target_group" "group" {
  name        = "web-ui"
  port        = 80
  protocol    = "TCP"
  vpc_id      = "vpc-05bb20e5204f2c6b4"
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    port                = "80"
    protocol            = "TCP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

