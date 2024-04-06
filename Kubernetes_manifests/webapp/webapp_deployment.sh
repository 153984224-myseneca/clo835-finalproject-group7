#!/bin/env bash
# For deployment of web_app deployment in EKS cluster for project2
# Author: Caleb U. Okon
# Date: 2024.04.06

read -p "Please input a namespace name: " NAMESPACE 
kubectl create ns ${NAMESPACE} || echo "Namespace ${NAMESPACE} already exists or failed to create."


echo ""
echo "Getting ECR credential..."
read -p "Please paste your ECR server address here: " ECR_SERVER
ECR_USERNAME="AWS"
ECR_PASS=$(aws ecr get-login-password --region us-east-1)
if [ $? -ne 0 ]; then
    echo "Failed to obtain ECR password. Ensure AWS CLI is configured correctly."
    exit 1
fi

read -p "Please paste your ECR WEBAPP image url here: " ECR_WEBAPP_IMAGE
echo "Updating webapp image in the manifest..."
sed -i "s|image: .*|image: ${ECR_WEBAPP_IMAGE}|" app_deployment.yaml

echo "Creating mysql-root-pass secret..."
kubectl -n ${NAMESPACE} apply -f mysql_secrets.yaml

echo "Creating ImagePullSecret..."
kubectl -n ${NAMESPACE} create secret docker-registry ecr-secret --docker-server=${ECR_SERVER} --docker-username=${ECR_USERNAME} --docker-password=${ECR_PASS}


echo ""
echo "Set your AWS credentials for S3 Bucket"
read -p "Please paste your AWS_ACCESS_KEY_ID here:  " YOUR_ACCESS_KEY_ID
read -p "Please paste your AWS_SECRET_ACCESS_KEY here: " YOUR_SECRET_ACCESS_KEY
read -p "Please paste your AWS_SESSION_TOKEN here: " YOUR_SESSION_TOKEN

# Create the Kubernetes secret
kubectl -n ${NAMESPACE} create secret generic aws-secret \
    --from-literal=aws_access_key_id="$AWS_ACCESS_KEY_ID" \
    --from-literal=aws_secret_access_key="$AWS_SECRET_ACCESS_KEY" \
    --from-literal=aws_session_token="$AWS_SESSION_TOKEN"

echo "Secrets in ${NAMESPACE}:"
kubectl -n ${NAMESPACE} get secret


echo ""
echo "Creating configMap for APP deployment..."
kubectl -n ${NAMESPACE} apply -f app_configmap.yaml

echo ""
echo "Creating WEBAPP deployment..."
kubectl -n ${NAMESPACE} apply -f app_deployment.yaml
sleep 5
kubectl -n ${NAMESPACE} get pod


echo ""
echo "Creating WEPAPP loadbalancer service..."
kubectl -n ${NAMESPACE} apply -f app_service.yaml
kubectl -n ${NAMESPACE} get svc

echo "Wait 10 seconds for pod creation..."
sleep 10
kubectl -n ${NAMESPACE} get pod

echo "WEBAPP Deployment process completed."
