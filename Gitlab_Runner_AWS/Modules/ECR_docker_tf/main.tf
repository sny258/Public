# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
#  backend "s3" {
#    bucket = "terraform-statefile-gitlabrunner"
#    key    = "state/gitlabrunner.tfstate"
#    region = "eu-wast-1"
#    encrypt = true
#    #dynamodb_table = "gitlabrunner-ddbt"					#for locking execution
#  }
# }

# Configure the AWS Provider
# provider "aws" {
#   region = var.location
#  access_key = "my-access-key"
#  secret_key = "my-secret-key"
# }

#####################################

resource "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_repo_name
  force_delete = true
}

data "aws_caller_identity" "current" {}

resource "null_resource" "docker_build_push" {
	provisioner "local-exec" {
	  command = <<EOF
	  aws ecr get-login-password --region ${var.location} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.location}.amazonaws.com
	  docker build -t ${aws_ecr_repository.ecr_repo.name}:${var.image_tag} -f Dockerfile-gitlabrunner-prestop .
      docker tag ${aws_ecr_repository.ecr_repo.name}:${var.image_tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.location}.amazonaws.com/${aws_ecr_repository.ecr_repo.name}:${var.image_tag}
	  docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.location}.amazonaws.com/${aws_ecr_repository.ecr_repo.name}:${var.image_tag}
	  EOF
	}
}