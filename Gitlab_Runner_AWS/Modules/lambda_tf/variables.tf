# Define variables
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
}

variable "lambda_func_name" {
  description = "The Lambda Function name."
}

variable "vpc_name" {
  description = "VPC where resources/infrastructure will be created "
  #default     = "Default"
}

variable "subnet_name" {
  description = "Subnet to be used for Autoscaling Group, with pricate subnet NATs EIP will be used for ASG"
}

variable "security_group_name" {
  description = "Security Group to be used for launch configuration for EC2"
}

variable "gitlab_url" {
  description = "URL of gitlab instance"
}

variable "gitlab_token" {
  description = "gitlab instance token"
}

variable "gitlab_project_name" {
  description = "Gitlab project name"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "ECS cluster service name"
  type        = string
}

variable "task_definition_family" {
  description = "Family name of the task definition"
  type        = string
}