#!/bin/sh

# Check if all required arguments are provided
if [ "$#" -ne 7 ]; then
  echo "Usage: $0 <region> <cluster_name> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_SESSION_TOKEN> <AWS_ACCESS_KEY_ID_s3> <AWS_SECRET_ACCESS_KEY_s3>"
  exit 1
fi

# Assign input arguments to variables
region=$1
cluster_name=$2
AWS_ACCESS_KEY_ID=$3
AWS_SECRET_ACCESS_KEY=$4
AWS_SESSION_TOKEN=$5
AWS_ACCESS_KEY_ID_s3=$6
AWS_SECRET_ACCESS_KEY_s3=$7

export region="$region"
export cluster_name="$cluster_name"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
export AWS_ACCESS_KEY_ID_s3="$AWS_ACCESS_KEY_ID_s3"
export AWS_SECRET_ACCESS_KEY_s3="$AWS_SECRET_ACCESS_KEY_s3"



#fetch the EKS cluster config
aws eks --region $region update-kubeconfig --name $cluster_name

#Add the metric server add-on
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

#Add the cluster autoscaler add-on
##Update cluster name beforehand at line 166
kubectl apply -f scripts/cluster-autoscaler-autodiscover.yaml

#Add helm repo for gitlab runner
helm repo add gitlab https://charts.gitlab.io -n gwl-runner
helm repo update gitlab -n gwl-runner

#create the namespace
kubectl create namespace gwl-runner

#create secrets for caching (optional)
##creds of a user in AWS, who has admin access to s3 buckets.
kubectl create secret generic s3access -n gwl-runner \
    --from-literal=accesskey=$AWS_ACCESS_KEY_ID_s3 \
    --from-literal=secretkey=$AWS_SECRET_ACCESS_KEY_s3

#update the values.yaml file, add all required values.

#deploy the gitlab-runner 
helm install --namespace gwl-runner gitlab-runner -f scripts/values.yaml gitlab/gitlab-runner

