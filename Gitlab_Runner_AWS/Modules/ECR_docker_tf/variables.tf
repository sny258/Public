# Define variables
variable "location" {
  description = "The location/region where resources/infrastructure will be created."
  #default     = "eu-west-1"
}

variable "ecr_repo_name" {
  description = "The Elastic Container Registry name."
  #default     = "ecr_gitlab_runner"
}

variable "image_tag" {
  description = "Tag for Docker image."
  #default     = "v1"
}