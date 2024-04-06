#!/bin/env bash
# For deployment of Service account, role, and role binding

read -p "Please input a namespace name: " NAMESPACE 
kubectl create ns ${NAMESPACE}

echo ""
echo "Creating Service Account 'clo835'..."
kubectl create sa clo835 -n ${NAMESPACE}
kubectl get sa -n ${NAMESPACE}

echo ""
echo "Creating Role 'clo835' for permissions to create and read namespaces..."
kubectl apply -f role.yaml -n ${NAMESPACE}
kubectl get roles -n ${NAMESPACE}

echo ""
echo "Creating RoleBinding 'clo835-role-binding' to binds role to erviceaccount...."
kubectl apply -f role_binding.yaml -n ${NAMESPACE}
kubectl get rolebindings -n ${NAMESPACE}

echo ""
echo "Service Account and Role Deployment process completed."