#!/bin/bash

APP_NAME=$1
DOCKER_USERNAME=$2
IMAGE_TAG=$3
ORG_NAME=$4
PROJECT_NAME=$5
REPO_NAME=$6
BRANCH_NAME="main"

echo "🔧 Parameters received:"
echo "APP_NAME=${APP_NAME}"
echo "DOCKER_USERNAME=${DOCKER_USERNAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "ORG_NAME=${ORG_NAME}"
echo "PROJECT_NAME=${PROJECT_NAME}"
echo "REPO_NAME=${REPO_NAME}"

# Use Azure DevOps token for authentication
AUTH_TOKEN=${SYSTEM_ACCESSTOKEN}

# Clean up if the directory already exists
rm -rf /tmp/${APP_NAME}_repo

# Clone the repo
REPO_URL="https://${AUTH_TOKEN}@dev.azure.com/${ORG_NAME}/${PROJECT_NAME}/_git/${REPO_NAME}"
echo "Cloning repo: $REPO_URL"

git clone --branch $BRANCH_NAME $REPO_URL /tmp/${APP_NAME}_repo

cd /tmp/${APP_NAME}_repo || { echo "Repository not found"; exit 1; }

# Make changes to the Kubernetes manifest file
# For example, let's say you want to change the image tag in a deployment.yaml file
echo "🔧 Updating Kubernetes manifest (deployment.yaml)"
sed -i "s|image:.*|image: ${DOCKER_USERNAME}/${APP_NAME}:${IMAGE_TAG}|g" k8s-specifications/$APP_NAME-deployment.yaml

# Check if the update was successful
if [ $? -eq 0 ]; then
    echo "✅ Kubernetes manifest updated successfully"
else
    echo "❌ Failed to update Kubernetes manifest"
    exit 1
fi

# Commit and push the changes
git config user.email "pipeline@dev.azure.com"
git config user.name "AzureDevOps Pipeline"
git add k8s-specifications/$APP_NAME-deployment.yaml
git commit -m "Updated ${APP_NAME} image to ${IMAGE_TAG}"
git push origin $BRANCH_NAME

echo "🔧 Kubernetes manifest updated and pushed successfully!"
