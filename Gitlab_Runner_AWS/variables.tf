######### Region & Network Vars #########
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  default     = "eu-west-1"
}

variable "vpc_name" {
  description = "VPC where resources/infrastructure will be created "
  default     = "Default"
  #default     = "vpc-f6822793"                   #vpc_id
}

variable "subnet_name" {
  description = "Subnet to be used for Autoscaling Group, with pricate subnet NATs EIP will be used for ASG"
  #default     = "public-default-eu-west-1c"       #public subnet from default VPC
  default     = "private-default"                #private subnet from default VPC
}

variable "security_group_name" {
  description = "Security Group to be used for launch configuration for EC2"
  default     = "GitlabRunnerTestSG"
  #default     = "sg-085ed924dcdaac13b"
}

######### ASG variables #############
variable "ami" {
  description = "Instance AMI which will be associated with ECS cluster"
  type        = string
  default     = "ami-0a8be929e170b87ff"       #Amazone Linux 2023
}

variable "instance_size" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.medium"
}

variable "key_pair" {
  description = "Key pair for EC2"
  type        = string
  default     = "GitlabRunnerTest-Key"
}

variable "elastic_ip_allocation_id" {
  description = "Allocation ID of EIP, Add value in case of public subnet other use NAT for private subnet"
  type        = string
  default     = "NAT"                              #99.80.102.35, NATs EIP of private subnet
  #default     = "eipalloc-0e28d092c7961bf20"      #63.34.73.169
}

variable "asg_max_size" {
  description = "max size of autoscaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "desired capacity of autoscaling group"
  type        = number
  default     = 1
}

######### ECS Cluster Vars ##########
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "gitlabrunner_cluster_AutoScaling"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "gitlabrunner_service_AutoScaling"
}

######### Gitlab Variables ########
variable "gitlab_url" {
  description = "URL of gitlab instance"
  default     = "https://sourcery-test.assaabloy.net"
}

variable "registration_token" {
  description = "Runner registration token"
  default     = "GR1348941ZgsmRxQ64xxxxxxxxxx"         #Test_GitlabGroup/GRdockertest_DinD
}

variable "runner_description" {
  description = "Runner Description"
  default     = "runner through ECS EC2"
}

variable "runner_executor" {
  description = "Runner Executor (docker/shell)"
  default     = "docker"
}

variable "runner_tags" {
  description = "Tags for runner"
  default     = "Docker,Script"
}

variable "gitlab_token" {
  description = "gitlab instance token"
  default     = "glpat-sv2qjuKxxxxxxxxxxx"
}

variable "gitlab_project_name" {
  description = "Gitlab project name"
  default     = "GRdockertest_DinD"
}

########## Task Definition Vars ########
variable "task_definition_family" {
  description = "Family name of the task definition"
  type        = string
  default     = "gitlabrunner_td_AutoScaling"
}

## Not required since ECR image will be created using terraform module,
## and output from that module will be used directly in the ecs_ec2 module.
# variable "container_image" {
#   description = "Container image to use"
#   type        = string
#   default     = "197517724303.dkr.ecr.eu-west-1.amazonaws.com/fargategitlabrunner:v1"
# }

variable "td_memory" {
  description = "Task Definition Memory"
  type = number
  default = 512
}

variable "td_cpu" {
  description = "Task Definition CPU"
  type = number
  default = 512
}

variable "desired_tasks" {
  description = "Desired Tasks in Service"
  type = number
  default = 1
}

######### Lambda Fucntion Vars #########
variable "lambda_func_name" {
  description = "The Lambda Function name."
  default     = "gr_test_lambda_func"
}

########### ECR variables ########
variable "ecr_repo_name" {
  description = "The Elastic Container Registry name."
  default     = "ecr_gitlab_runner"
}

variable "image_tag" {
  description = "Tag for Docker image."
  default     = "v1"
}
