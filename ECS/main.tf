
resource "aws_ecr_repository" "monitoring-app_ecr" {
  name                 = var.application_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_cluster" "monitoring-app" {
  name = var.application_name
}
resource "aws_ecs_task_definition" "monitoring-app" {
  family                   = var.application_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu_size #"256"
  memory                   = var.ecs_task_memory_size # "512"
  container_definitions    = <<DEFINITION
[
  {
    "name": "${var.application_name}",
    "image": "${aws_ecr_repository.monitoring-app_ecr.repository_url}:${var.image_tag}", 
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring-app.name}",
        "awslogs-region": "${local.region_name}",
        "awslogs-stream-prefix": "${var.application_name}"
      }
    }
  }
]
DEFINITION
  execution_role_arn       = aws_iam_role.task_definition_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
resource "aws_cloudwatch_log_group" "monitoring-app" {
  name = "/ecs/${var.application_name}"
}
resource "aws_ecs_service" "monitoring-app" {
  name            = var.application_name
  cluster         = aws_ecs_cluster.monitoring-app.id
  task_definition = aws_ecs_task_definition.monitoring-app.arn
  desired_count   = var.ecs_task_desired_count
  force_new_deployment = true
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.monitoring-app.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.monitoring-app.arn
    container_name   = var.application_name
    container_port   = 5000
  }
}
resource "aws_security_group" "monitoring-app" {
  name        = var.application_name
  description = "Allow inbound traffic to flask app"
  vpc_id      = var.vpc_id
  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_lb_target_group" "monitoring-app" {
  name        = var.application_name
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb" "monitoring-app" {
  name                       = var.application_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.monitoring-app.id]
  subnets                    = var.subnets
  enable_deletion_protection = false
  tags = {
    Name = "${var.application_name}"
  }
}
resource "aws_lb_listener" "monitoring-app" {
  load_balancer_arn = aws_lb.monitoring-app.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring-app.arn
  }
}
resource "aws_lb_listener_rule" "monitoring-app" {
  listener_arn = aws_lb_listener.monitoring-app.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring-app.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
resource "aws_iam_role" "task_definition_role" {
  name               = "flask_task_definition"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "task_definition_policy" {
  name   = "definition_policy"
  role   = aws_iam_role.task_definition_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}