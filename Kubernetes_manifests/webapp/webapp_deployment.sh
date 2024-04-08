#!/bin/env bash
# For deployment of Webapp in EKS cluster for Project2
# Author: Caleb U. Okon
# Credit: Zhiwei (Jon) Zeng
# Date: 2024.04.06

read -p "Please input a namespace name: " NAMESPACE 
kubectl create ns ${NAMESPACE} || echo "Namespace ${NAMESPACE} already exists or failed to create."

# echo "Listing available StorageClasses..."
# kubectl get sc

# echo ""
# echo "Deploying a new StorageClass for S3 Bucket Background Image..."
# kubectl -n ${NAMESPACE} apply -f image_storageclass.yaml
# echo "Updated StorageClasses:"
# kubectl get sc

echo ""
echo "Creating a PVC for S3 Bucket Background Image..."
kubectl -n ${NAMESPACE} apply -f image_pvc.yaml


read -p "Please paste your Webapp image URL for the here: " ECR_WEBAPP_IMAGE
echo "Updating Webapp image in the maifest..."
sed -i "s|image: .*|image: ${ECR_WEBAPP_IMAGE}|" app_deployment.yaml


# echo ""
# echo "Creating mysql-root-pass secret..."
# kubectl -n ${NAMESPACE} create secret generic mysql-secret \
# 	  --from-literal="username=root" \
# 	  --from-literal="password=pw"

# echo ""
# echo "Creating ImagePullSecret..."
# kubectl -n ${NAMESPACE} create secret docker-registry ecr-secret --docker-server=${ECR_SERVER} --docker-username=${ECR_USERNAME} --docker-password=${ECR_PASS}


echo ""
echo "Set your AWS credentials for S3 Bucket"
read -p "Please paste your AWS_ACCESS_KEY_ID here: " YOUR_ACCESS_KEY_ID
read -p "Please paste your AWS_SECRET_ACCESS_KEY here: " YOUR_SECRET_ACCESS_KEY
read -p "Please paste your AWS_SESSION_TOKEN here: " YOUR_SESSION_TOKEN


kubectl -n ${NAMESPACE} create secret generic aws-secret \
    --from-literal=aws_access_key_id="$AWS_ACCESS_KEY_ID" \
    --from-literal=aws_secret_access_key="$AWS_SECRET_ACCESS_KEY" \
    --from-literal=aws_session_token="$AWS_SESSION_TOKEN"

echo "Secrets in ${NAMESPACE}:"
kubectl -n ${NAMESPACE} get secret


echo ""
read -p "Please input your S3 Image bucket name: " S3_BUCKET_NAME
read -p "Please input the image name: " IMAGE_NAME

echo ""
echo "Creating configMap for WEBAPP deployment..."
sed -i "s|bucket_name:.*|bucket_name: \"$S3_BUCKET_NAME\"|" app_configmap.yaml
sed -i "s|image_name:.*|image_name: \"$IMAGE_NAME\"|" app_configmap.yaml

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
