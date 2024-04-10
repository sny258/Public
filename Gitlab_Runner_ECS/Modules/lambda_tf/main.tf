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


######### IAM role creation ##########
##### IAM role for lambda fucntion, where required policies will be addedd #####
resource "aws_iam_role" "aws_lambda_role" {
  name = "aws_lambda_role_as"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#creating custom policies for basic execution
resource "aws_iam_policy" "lambda_basic_execution_policy" {
  name        = "lambda_basic_execution_policy_as"
  description = "IAM policy for lambda basic execution"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EIPAssociation",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
		      "logs:CreateLogStream",
		      "logs:PutLogEvents"
        ],
        "Resource" = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

#creating custom policies for lambda VPC access
resource "aws_iam_policy" "lambda_vpc_access_policy" {
  name        = "lambda_vpc_access_policy_as"
  description = "IAM policy for lambda VPC access"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EIPAssociation",
        "Effect": "Allow",
        "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ],
        "Resource": "*"
      }
    ]
  })
}

#creating custom policies for sending metrics to cloudwatch
resource "aws_iam_policy" "cloudwatch_put_policy" {
  name        = "cloudwatch_put_policy_as"
  description = "IAM policy to send cloudwatch metric"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EIPAssociation",
        "Effect": "Allow",
        "Action": [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags"
        ],
        "Resource": "*"
      }
    ]
  })
}

#adding predefined policy to IAM role
resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  role       = aws_iam_role.aws_lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution_policy.arn           #attaching custom policies
}
resource "aws_iam_role_policy_attachment" "lambda_role_attachment1" {
  role       = aws_iam_role.aws_lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_access_policy.arn                #attaching custom policies
}
resource "aws_iam_role_policy_attachment" "lambda_role_attachment2" {
  role       = aws_iam_role.aws_lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_put_policy.arn                   #attaching custom policies
}

#####################################
# Lambda automatically creates a log group when your Lambda function is first invoked.
##### logging system for lambda #####
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   name = "/aws/lambda/${var.lambda_func_name}"
#   retention_in_days = 30
# }


############# creating lambda function ##############
resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_func_name
  filename         = "my_lambda_function.zip"
  source_code_hash = filebase64sha256("my_lambda_function.zip")
  handler          = "lambda_function.lambda_handler"				            #"index.handler"
  role             = aws_iam_role.aws_lambda_role.arn
  runtime          = "python3.9"
  timeout          = 30                                               #function exec timeout
  memory_size      = 256                                              #memory for function
  vpc_config {
    subnet_ids = [data.aws_subnet.subnet.id]
    security_group_ids = [data.aws_security_group.sg.id]
  }
  environment {
    variables = {
      GITLAB_URL      = var.gitlab_url
      PRIVATE_TOKEN   = var.gitlab_token
      PROJECT_NAME    = var.gitlab_project_name
    }
  }
}


#################### EventBridge trigger for Lambda ##################
resource "aws_cloudwatch_event_rule" "eventbridge_event_rule" {
    name = "lambda_eb_rule"
    description = "Fires every minute"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda_every_target" {
    rule = aws_cloudwatch_event_rule.eventbridge_event_rule.name
    #target_id = var.lambda_func_name
    arn = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromEventBridge"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.eventbridge_event_rule.arn
}


############################################
# Once eventbridge is created, it will send the custom metric to AWS cloudwatch.
# USing that custom metric, Cloudwatch alarm will be created.


######## Creating Cloudwatch Alarm ###############
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name           = "${var.lambda_func_name}_alarm_SO"
  comparison_operator  = "GreaterThanThreshold"
  evaluation_periods   = 1                             # No. of breaches before trigger
  metric_name          = "Pending_Pipelines"
  namespace            = "GitLab_Project_Pipeline_Metrics_TF"
  period               = 60                             # Period to evaluate metric
  statistic            = "Minimum"
  threshold            = 0                             # Pending_Pipelines > 0 every minute
  alarm_description    = "This metric alarm is triggered when pending pipelines > 0 every minute"
  datapoints_to_alarm  = 1
  #dimensions           = "${var.gitlab_project_name}_pending_pipeline" 
  dimensions = {
    "${var.gitlab_project_name}_pipelines" = "${var.gitlab_project_name}_pipelines" 
  }
  #unit                 = "count"
  alarm_actions = [aws_appautoscaling_policy.scale_out_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name           = "${var.lambda_func_name}_alarm_SI"
  comparison_operator  = "LessThanThreshold"
  evaluation_periods   = 1                             # No. of breaches before trigger
  metric_name          = "Running_Pipelines"
  namespace            = "GitLab_Project_Pipeline_Metrics_TF"
  period               = 60                             # Period to evaluate metric
  statistic            = "Minimum"
  threshold            = 1                             # Running_Pipelines < 1 every minute
  alarm_description    = "This metric alarm is triggered when running pipelines < 1 every minute"
  datapoints_to_alarm  = 1
  dimensions = {
    "${var.gitlab_project_name}_pipelines" = "${var.gitlab_project_name}_pipelines" 
  }
  #unit                 = "count"
  alarm_actions = [aws_appautoscaling_policy.scale_in_policy.arn]
}


resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 6
}

resource "aws_appautoscaling_policy" "scale_out_policy" {
  name               = "${var.service_name}_scale_out_policy"
  #depends_on         = [aws_appautoscaling_target.scale_target]
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 5
    metric_aggregation_type = "Minimum"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in_policy" {
  name               = "${var.service_name}_scale_in_policy"
  #depends_on         = [aws_appautoscaling_target.scale_target]
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 5
    metric_aggregation_type = "Minimum"
    step_adjustment {
      metric_interval_upper_bound  = 0
      scaling_adjustment           = -1
    }
  }
}