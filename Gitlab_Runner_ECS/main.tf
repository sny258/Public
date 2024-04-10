terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
#  backend "s3" {
#    bucket = "terraform-statefile-gitlabrunner"
#    key    = "state/gitlabrunner.tfstate"
#    region = "eu-wast-1"
#    encrypt = true
#    #dynamodb_table = "gitlabrunner-ddbt"					#for locking execution
#  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.location
#  access_key = "my-access-key"
#  secret_key = "my-secret-key"
}

module "ECR_docker_tf" {
  source            = "./modules/ECR_docker_tf"
  ecr_repo_name     = var.ecr_repo_name
  location          = var.location
  image_tag         = var.image_tag
}

module "ecs_ec2_tf" {
  source                    = "./modules/ecs_ec2_tf"
  location                  = var.location
  vpc_name                  = var.vpc_name
  subnet_name               = var.subnet_name
  security_group_name       = var.security_group_name
  ami                       = var.ami
  instance_size             = var.instance_size
  key_pair                  = var.key_pair
  elastic_ip_allocation_id  = var.elastic_ip_allocation_id
  asg_max_size              = var.asg_max_size
  desired_capacity          = var.desired_capacity
  cluster_name              = var.cluster_name
  gitlab_url                = var.gitlab_url
  registration_token        = var.registration_token
  runner_description        = var.runner_description
  runner_executor           = var.runner_executor
  runner_tags               = var.runner_tags
  task_definition_family    = var.task_definition_family
  #container_image           = var.container_image               #module.ECR_docker_tf.ecr_image (output.tf)
  container_image           = module.ECR_docker_tf.ecr_image
  td_memory                 = var.td_memory
  td_cpu                    = var.td_cpu
  desired_tasks             = var.desired_tasks
  service_name              = var.service_name
  depends_on                = [module.ECR_docker_tf]
}

module "lambda_tf" {
  source                    = "./modules/lambda_tf"
  location                  = var.location
  vpc_name                  = var.vpc_name
  subnet_name               = var.subnet_name
  security_group_name       = var.security_group_name
  lambda_func_name          = var.lambda_func_name
  gitlab_url                = var.gitlab_url
  gitlab_token              = var.gitlab_token
  gitlab_project_name       = var.gitlab_project_name
  cluster_name              = var.cluster_name
  service_name              = var.service_name
  task_definition_family    = var.task_definition_family
  depends_on                = [module.ecs_ec2_tf]
}