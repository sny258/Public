# Output the ECS cluster name
# data "aws_instances" "ecs_ec2" {
#   filter {
#     name   = "tag:Name"
#     values = ["ECS Instance - ${var.cluster_name}#DoNotDelete"]
#   }
# }

# output "ec2_instance_public_ip" {
#   value = data.aws_instances.ecs_ec2.public_ips
# }

output "ecr_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "ecr_image" {
  value = "${aws_ecr_repository.ecr_repo.repository_url}:${var.image_tag}"
}