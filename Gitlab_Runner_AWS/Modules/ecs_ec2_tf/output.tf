# Output the ECS cluster name
data "aws_instances" "ecs_ec2" {
  filter {
    name   = "tag:Name"
    values = ["ECS Instance - ${var.cluster_name}#DoNotDelete"]
  }
}

output "ec2_instance_public_ip" {
  value = data.aws_instances.ecs_ec2.public_ips
}

output "asg_arn" {
  value = aws_autoscaling_group.gitlabrunner_asg.arn
}