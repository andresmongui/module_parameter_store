resource "aws_ecs_cluster" "cluster" {
  name = "unum"
}

resource "aws_ecs_task_definition" "task" {
  family                = "service"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE_SPOT"]
  cpu                   = "256"
  memory                = "512"
  
  container_definitions = jsonencode([
    {
      "name": "service",
      "image": "service:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ]
    }
  ])
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-abcde012"

  ingress {
    from_port   = 8444
    to_port     = 8444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  security_groups    = [aws_security_group.lb_sg.id]

  enable_deletion_protection = true
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "8444"
  protocol          = "TLS"
  certificate_arn   = "arn:aws:acm:us-west-2:123456789012:certificate/7a58ad"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.group.arn
  }
}

resource "aws_security_group" "fargate_sg" {
  name        = "fargate_sg"
  description = "Allow inbound traffic"
  vpc_id      = "vpc-abcde012"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "service" {
  name            = "service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE_SPOT"
  network_configuration {
    security_groups = [aws_security_group.fargate_sg.id]
    subnets         = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.group.arn
    container_name   = "service"
    container_port   = 8080
  }
}

