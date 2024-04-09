#!/bin/env bash
# For deployment of mysql deployment in EKS cluster for project2
# Author: Zhiwei (Jon) Zeng
# Date: 2024.03.30

read -p "Please input a namespace name: " NAMESPACE 
kubectl create ns ${NAMESPACE} || echo "Namespace ${NAMESPACE} already exists or failed to create."

echo "Listing available StorageClasses..."
kubectl get sc

echo ""
echo "Deploying a new StorageClass..."
kubectl -n ${NAMESPACE} apply -f sc.yaml
echo "Updated StorageClasses:"
kubectl get sc


echo ""
echo "Getting ECR credential..."
read -p "Please paste your ECR MySQL image url here: " ECR_MYSQL_IMAGE
ECR_SERVER=$(echo $ECR_MYSQL_IMAGE | awk -F'/' '{print $1}') 
ECR_USERNAME="AWS"
ECR_PASS=$(aws ecr get-login-password --region us-east-1)
if [ $? -ne 0 ]; then
    echo "Failed to obtain ECR password. Ensure AWS CLI is configured correctly."
    exit 1
fi

#read -p "Please paste your ECR MySQL image url here: " ECR_MYSQL_IMAGE
echo "Updating mysql image in the manifest..."
sed -i "s|image: .*|image: ${ECR_MYSQL_IMAGE}|" mysql_deployment.yaml

echo "Creating mysql-root-pass secret..."
read "Please enter the db password: " DBPASSWD
kubectl -n ${NAMESPACE} create secret generic mysql-root-pass --from-literal=password='"${DBPASSWD}"'

echo "Creating ImagePullSecret..."
kubectl -n ${NAMESPACE} create secret docker-registry ecr-secret --docker-server=${ECR_SERVER} --docker-username=${ECR_USERNAME} --docker-password=${ECR_PASS}
echo "Secrets in ${NAMESPACE}:"
kubectl -n ${NAMESPACE} get secret

echo ""
echo "Creating a PVC for mysql deployment..."
kubectl -n ${NAMESPACE} apply -f mysql_pvc.yaml

echo ""
echo "Creating mysql deployment..."
kubectl -n ${NAMESPACE} apply -f mysql_deployment.yaml
sleep 5
kubectl -n ${NAMESPACE} get pvc
kubectl -n ${NAMESPACE} get pv

echo ""
echo "Creating mysql service..."
kubectl -n ${NAMESPACE} apply -f mysql_service.yaml
kubectl -n ${NAMESPACE} get svc

echo "Wait 10 seconds for pod creation..."
sleep 10
kubectl -n ${NAMESPACE} get pod

echo "Deployment process completed."
