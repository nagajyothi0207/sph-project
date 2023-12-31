variable "aws_region" {
  default = "ap-southeast-1"
}
variable "vpc_id" {
  default = "vpc-0a33ca42de6280a66"
}
variable "subnets" {
  type = list(string)
  default = [
    "subnet-03746b2129f87b33b",
    "subnet-0218c046651cff784",
    "subnet-005acbfdd0aa7ecac"
  ]
}
variable "image_tag" {
  default = "latest"
}

variable "application_name" {
  default = "monitoring-app"
}

variable "ecs_task_desired_count" {
  default = "2"
}

variable "ecs_task_cpu_size" {
  default = "256"
}

variable "ecs_task_memory_size" {
  default = "512"
}
