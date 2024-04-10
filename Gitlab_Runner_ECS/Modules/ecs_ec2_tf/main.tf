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
#}

# # Configure the AWS Provider
# provider "aws" {
#   region = var.location
# #  access_key = "my-access-key"
# #  secret_key = "my-secret-key"
# }

################################
#when using VPC, Subnet and SG names
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "subnet" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

data "aws_security_group" "sg" {
  name = var.security_group_name
}

#####################################
######### IAM role  ##########
## IAM role for EC2 instance, where all policies will be addedd
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_instance_role_as"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#creating custom policies for allocating/de-allocating EIP
resource "aws_iam_policy" "instance_policy" {
  name        = "policy_for_eip_association_as"
  description = "IAM policy for EIP association"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EIPAssociation",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeAddresses",
          "ec2:AllocateAddress",
          "ec2:DescribeInstances",
          "ec2:AssociateAddress"
        ],
        "Resource": "*"
      }
    ]
  })
}

#adding predefined policy to IAM role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment1" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn           #attaching custom policies
}

#instance profile which will be the bridge between EC2 and IAM role.
#this will be attached to EC2 machine, no the IAM role
resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs_instance_role.name
}

############### Iam role for task defination or containers #########
resource "aws_iam_role" "ecsTaskExecutionRole1" {
  name = "ecsTaskExecutionRole1_as"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole1.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##### Iam role for task to interact with AWS services #####
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role_as"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ecs_task_role.name
}


##### aws launch configuration for ec2 ######
resource "aws_launch_template" "gitlabrunner_lt" {
  name_prefix          = "${var.cluster_name}_launch_template-"
  image_id             = var.ami
  instance_type        = var.instance_size
  key_name             = var.key_pair
  lifecycle {
    create_before_destroy = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_service_role.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [data.aws_security_group.sg.id]
  }
  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y openssl
#Retrieve the Elastic IP allocation ID from the variable
allocation_id="${var.elastic_ip_allocation_id}"
echo $allocation_id
if [ "$allocation_id" != "NAT" ]; then
  #Retrieve the instance ID
  TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
  instance_id="$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)"
  echo $instance_id
  #Associate Elastic IP with the instance
  aws ec2 associate-address --instance-id "$instance_id" --allocation-id "$allocation_id"
else
  echo "Private Subnet is used, so NAT ip will be used to connect to Gitlab server"
fi
#sleep for 30 sec
sleep 30
#for registering EC2 as instance inside ECS cluster
echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
#Downloading and Adding gitlab certs for docker
gitlab_url_without_https=$(echo "${var.gitlab_url}" | sed 's/^https:\/\///')
mkdir -p /etc/docker/certs.d/registry.$gitlab_url_without_https
openssl s_client -showcerts -connect $gitlab_url_without_https:443 -servername $gitlab_url_without_https < /dev/null 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/, /-----END CERTIFICATE-----/' > /etc/docker/certs.d/registry.$gitlab_url_without_https/$gitlab_url_without_https.crt
EOF
  )
}

##### autoscaling group for ECS ######
resource "aws_autoscaling_group" "gitlabrunner_asg" {
  name_prefix               = "${var.cluster_name}_asg-"
  launch_template {
    id      = aws_launch_template.gitlabrunner_lt.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = var.asg_max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = [data.aws_subnet.subnet.id]
  #protect_from_scale_in     = false
  #termination_policies      = ["NewestInstance"]
  protect_from_scale_in     = true
  lifecycle {
    create_before_destroy    = true
  }
  tag {
    key                 = "Name"
    value               = "ECS Instance - ${var.cluster_name}#DoNotDelete"
    propagate_at_launch = true
  }
}


###############################
###### aws ECS cluster ########
resource "aws_ecs_cluster" "gitlabrunner_cluster" {
  name               = var.cluster_name
}

##########################################
####### aws ECS capacity provider ########
resource "aws_ecs_capacity_provider" "gitlabrunner_cp" {
  name = "${var.cluster_name}_capacity_providers"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.gitlabrunner_asg.arn
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100                         #If utilization more than 100%, ASG will scale-out
    }
    managed_termination_protection = "ENABLED"      #Instance running tasks won't scale-in, but for this ASG should have scale-in protection in place
  }
}

####### associate capacity provider with ecs cluster ######
resource "aws_ecs_cluster_capacity_providers" "gitlabrunner_capacity_providers" {
  cluster_name       = aws_ecs_cluster.gitlabrunner_cluster.name    #id
  capacity_providers = [aws_ecs_capacity_provider.gitlabrunner_cp.name]

  default_capacity_provider_strategy {
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.gitlabrunner_cp.name
  }
}


#####################################
##### logging system for ECS td #####
resource "aws_cloudwatch_log_group" "ecs_runner_lg" {
  name = "/ecs/${var.task_definition_family}"
  retention_in_days = 30
}


################################################
######## gitlabrunner task definitions #########
resource "aws_ecs_task_definition" "gitlabrunner_td" {
  family                   = var.task_definition_family
  container_definitions    = jsonencode([
    {
      name          = "gitlabrunner"
      image         = var.container_image
      mountPoints = [
      {
        sourceVolume= "socket",
        containerPath = "/var/run/docker.sock"
      }],

      environment = [
        {
          name  = "GITLAB_URL"
          value = var.gitlab_url
        },
        {
          name  = "REGISTRATION_TOKEN"
          value = var.registration_token
        },
        {
          name  = "RUNNER_DESCRIPTION"
          value = var.runner_description
        },
        {
          name  = "RUNNER_EXECUTOR"
          value = var.runner_executor
        },
        {
          name  = "RUNNER_TAGS"
          value = var.runner_tags
        }
      ],
      HealthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f https://sourcery-test.assaabloy.net|| exit 1"
          #"nc -z -w5 18.192.35.207 443"
        ],
        retries = 10,
        startPeriod = 30,
        interval = 10,
        timeout = 5             #Mentioning default values so that terraform plan don't detect changes
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.task_definition_family}",
          "awslogs-region": var.location,
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      restartPolicy = "RESTART"
      # Mentioning default values so that terraform plan don't detect changes for these 
      cpu              = 0
      essential        = true
      portMappings     = []
      volumesFrom      = []
    }
  ])

  volume {
    name      = "socket"
    host_path  = "/var/run/docker.sock"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags                     = {}               #Mentioning default values so that terraform plan don't detect changes 
  requires_compatibilities = ["EC2"] 
  network_mode             = "host"    
  memory                   = var.td_memory
  cpu                      = var.td_cpu 
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole1.arn
}


################################################
###### ECS service for gitlabrunner #############
resource "aws_ecs_service" "gitlabrunner_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.gitlabrunner_cluster.id
  task_definition = aws_ecs_task_definition.gitlabrunner_td.arn
  desired_count   = var.desired_tasks
  #launch_type     = "EC2"

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gitlabrunner_cp.name
    weight            = 100
  }

  #force_new_deployment = true
  
  deployment_circuit_breaker {
    enable            = true
    rollback          = true
  }
  
  provisioner "local-exec" {
      when = destroy
	    command = <<EOF
	    echo "Update service desired count to 0 before destroy."
      #Get region out of cluster
      REGION=$(echo ${self.cluster} | cut -d':' -f4)
      echo "Region: $REGION"
      #Set the Service desired count to 0
      aws ecs update-service --region $REGION --cluster ${self.cluster} --service ${self.name} --desired-count 0 --force-new-deployment 
	    echo "Update service command executed successfully."
      EOF
	  }

  timeouts {
    #create = "10m"  # Timeout for resource creation
    delete = "5m"  # Timeout for resource deletion
  }

  #for 'host' type network configuration in task definition, network_configuration block is not required since it will take config from host which is running the container.
  # network_configuration {
  #   subnets          = [data.aws_subnet.subnet.id]
  #   security_groups  = [data.aws_security_group.sg.id]
  # }
}



