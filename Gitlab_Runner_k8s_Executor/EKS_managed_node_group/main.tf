terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  #  backend "s3" {
  #    bucket = "terraform-statefile-gitlabrunner"
  #    key    = "statefile/k8gitlabrunner.tfstate"
  #    region = "eu-west-1"
  #    encrypt = true
  #  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}


### Iam (pass the required var) ###
module "IAM" {
  source                 = "./modules/IAM"
  eks_cluster_role_tags  = var.eks_cluster_tags
  cluster_name           = var.cluster_name
}


### EKS ###
module "EKS" {
  source       = "./modules/EKS"
  cluster_name = var.cluster_name
  #vpc_id         					         = var.vpc_id                        #required if secondry SG needed
  cluster_version                  = var.cluster_version
  cluster_iam_role                 = module.IAM.eks_cluster_role_arn
  subnet_ids                       = var.subnet_ids
  cluster_endpoint_private_access  = var.cluster_endpoint_private_access
  cluster_endpoint_public_access   = var.cluster_endpoint_public_access
  cluster_public_access_cidrs      = var.cluster_public_access_cidrs
  eks_node_group                   = var.eks_node_group
  node_iam_role                    = module.IAM.node_group_role_arn
  instance_type                    = var.instance_type
  disk_size                        = var.disk_size
  capacity_type                    = var.capacity_type
  ami_type                         = var.ami_type
  min_size                         = var.min_size
  max_size                         = var.max_size
  desired_size                     = var.desired_size
  labels                           = var.labels
  eks_cluster_tags                 = var.eks_cluster_tags
  depends_on = [
    module.IAM
  ]
}



# #Install addon and runner on cluster
# resource "null_resource" "cluster_addons" {
# 	provisioner "local-exec" {
# 	  command = <<EOF
#     chmod +x ./scripts/cluster_addons.sh
#     ./scripts/cluster_addons.sh "${var.aws_region}" "${var.cluster_name}" "${var.aws_access_key_id}" "${var.aws_secret_access_key}" "${var.aws_session_token}" "${var.aws_access_key_id_s3}" "${var.aws_secret_access_key_s3}"
#     EOF
# 	}
#   depends_on = [
#     module.IAM,
#     module.EKS
#   ]
# }


#By-default null resource executes only once at terraform apply
#Install addon and runner on cluster
resource "null_resource" "cluster_addons" {
	triggers = {                                        #trigger to execute null every time
    #id = module.EKS.cluster_endpoint
    file_changed = md5(file("scripts/values.yaml"))
	  file_changed = md5(file("scripts/cluster_addons.sh"))  
  }
  provisioner "local-exec" {
	  command = <<EOF
    #Replace the image value
    #check the latest version at: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    sed -i 's|image: .*|image: eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.26.2|' scripts/cluster-autoscaler-autodiscover.yaml
    #Replace the <your_eks_cluster> value
    sed -i 's|node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/.*|node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}|' scripts/cluster-autoscaler-autodiscover.yaml
    #Give premission to cluster addon file
    chmod +x ./scripts/cluster_addons.sh
    ./scripts/cluster_addons.sh "${var.aws_region}" "${var.cluster_name}" "${var.aws_access_key_id}" "${var.aws_secret_access_key}" "${var.aws_session_token}" "${var.aws_access_key_id_s3}" "${var.aws_secret_access_key_s3}"
    EOF
	}
  depends_on = [
    module.IAM,
    module.EKS
  ]
}


#Replace the image value
#sed -i 's|image: <image_region>/k8s-artifacts-prod/autoscaling/cluster-autoscaler:<image_version_tag>|image: new_image_region/k8s-artifacts-prod/autoscaling/cluster-autoscaler:new_image_version_tag|' your_yaml_file.yaml
