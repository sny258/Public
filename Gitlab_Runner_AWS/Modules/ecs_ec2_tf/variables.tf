######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
}

variable "vpc_name" {
  description = "VPC where resources/infrastructure will be created "
}

variable "subnet_name" {
  description = "Subnet to be used for Autoscaling Group, with pricate subnet NATs EIP will be used for ASG"
}

variable "security_group_name" {
  description = "Security Group to be used for launch configuration for EC2"
}

######### ASG variables #############
variable "ami" {
  description = "Instance AMI which will be associated with ECS cluster"
  type        = string
}

variable "instance_size" {
  description = "EC2 instance size"
  type        = string
}

variable "key_pair" {
  description = "Key pair for EC2"
  type        = string
}

variable "elastic_ip_allocation_id" {
  description = "Allocation ID of EIP, Add value in case of public subnet other use NAT for private subnet"
  type        = string
}

variable "asg_max_size" {
  description = "max size of autoscaling group"
  type        = number
}

variable "desired_capacity" {
  description = "desired capacity of autoscaling group"
  type        = number
}

######### ECS Cluster Vars ##########
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

######### Gitlab Variables ########
variable "gitlab_url" {
  description = "URL of gitlab instance"
}

variable "registration_token" {
  description = "Runner registration token"
}

variable "runner_description" {
  description = "Runner Description"
}

variable "runner_executor" {
  description = "Runner Executor (docker/shell)"
}

variable "runner_tags" {
  description = "Tags for runner"
}

########## Task Definition Vars ########
variable "task_definition_family" {
  description = "Family name of the task definition"
  type        = string
}

variable "container_image" {
  description = "Container image to use"
  type        = string
}

variable "td_memory" {
  description = "Task Definition Memory"
  type = number
}

variable "td_cpu" {
  description = "Task Definition CPU"
  type = number
}

variable "desired_tasks" {
  description = "Desired Tasks in Service"
  type = number
}