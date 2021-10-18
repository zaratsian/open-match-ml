# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file contains the sample minimal pod definitions for all of the components that one may need to use Open Match as a match maker.
# You can find the same pod definitions within the sub-folders under the /tutorials/ directory
# Run `kubectl apply -f matchmaker.yaml` to deploy these definitions.

# NOTE: This script assumes that 
# Docker and the gcloud SDK are 
# already installed on your machine.

# Load Config
. ./config

# Enable necessary GCP services
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Setup Google Artifact Registry
gcloud artifacts repositories create ${GCP_ARTIFACT_REGISTRY_NAME} \
--repository-format=docker \
--location=${GCP_ARTIFACT_REGISTRY_REGION} \
--description="Open Match Docker Repo"

# Verify that repo has been created
#gcloud artifacts repositories list

# Set up authentication to Docker repositories in the region
gcloud auth configure-docker "${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev"

###########################################
# Create a GKE Cluster in this project
###########################################
# https://cloud.google.com/sdk/gcloud/reference/container/clusters/create

gcloud container clusters create ${GKE_CLUSTER_NAME} \
    --enable-ip-alias \
    --machine-type ${GKE_MACHINE_TYPE} \
    --zone ${GKE_MACHINE_ZONE} \
    --num-nodes=${GKE_MIN_NODES} \
    --enable-autoscaling \
    --min-nodes=${GKE_MIN_NODES} \
    --max-nodes=${GKE_MAX_NODES} \
    --tags ${GKE_CLUSTER_TAGS}

# Get kubectl credentials against GKE
# Updates a kubeconfig file with appropriate credentials and 
# endpoint information to point kubectl at a specific cluster in 
# Google Kubernetes Engine
# https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --zone ${GKE_MACHINE_ZONE}

# Explicitly create namepace
kubectl create namespace ${NAMESPACE_OPEN_MATCH}

###########################################
# Install the core Open Match services.
###########################################
# 01-open-match-core.yaml installs Open Match with the default configs.

kubectl apply --namespace ${NAMESPACE_OPEN_MATCH} \
    -f https://open-match.dev/install/v1.2.0/yaml/01-open-match-core.yaml

# Get the Pod State
# NOTE: Open Match needs to be customized to run as a Matchmaker.
# This custom configuration is provided to the Open Match 
# components via a ConfigMap (om-configmap-override). 
# Thus, starting the core service pods will remain in 
# ContainerCreating until this config map is available.
kubectl get -n open-match pod

# Install the Default Evaluator
kubectl apply --namespace ${NAMESPACE_OPEN_MATCH} \
    -f https://open-match.dev/install/v1.2.0/yaml/06-open-match-override-configmap.yaml \
    -f https://open-match.dev/install/v1.2.0/yaml/07-open-match-default-evaluator.yaml

###########################################
#   Deploy Frontend
###########################################
. ./config

REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
echo "Artifact Registry Path: ${REGISTRY}"

# Create Namespace
kubectl create namespace ${NAMESPACE_MATCHMAKER}

# Build the Frontend image.
docker build -t $REGISTRY/${NAMESPACE_MATCHMAKER}-frontend -f frontend/Dockerfile .

# Push the Frontend image to the configured Registry.
docker push $REGISTRY/${NAMESPACE_MATCHMAKER}-frontend

###########################################
#   Deploy Director
###########################################

REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
echo "Artifact Registry Path: ${REGISTRY}"

#kubectl create namespace ${NAMESPACE_MATCHMAKER}

# Update go file with reference to NAMESPACE_MATCHMAKER
mv ./director/main.go ./main.go
sed "s|NAMESPACE_MATCHMAKER|$NAMESPACE_MATCHMAKER|g" ./main.go >> ./director/main.go

# Build the image.
docker build -t $REGISTRY/${NAMESPACE_MATCHMAKER}-director -f director/Dockerfile .

# Cleanup - Restore main.go to original
mv ./main.go ./director/main.go

# Push the image to the configured Registry.
docker push $REGISTRY/${NAMESPACE_MATCHMAKER}-director

###########################################
#   Deploy Match Function
###########################################

REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
echo "Artifact Registry Path: ${REGISTRY}"

#kubectl create namespace ${NAMESPACE_MATCHMAKER}

# Build the image.
docker build -t $REGISTRY/${NAMESPACE_MATCHMAKER}-matchfunction -f matchfunction/Dockerfile .

# Push the image to the configured Registry.
docker push $REGISTRY/${NAMESPACE_MATCHMAKER}-matchfunction

###########################################
#   Deploy - Apply all Configs
###########################################

REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
echo "Artifact Registry Path: ${REGISTRY}"

# Deploy the Match Function, the Game Frontend and the Director 
# to the same cluster as Open Match deployment but to a different namespace. 
# The $TUTORIALROOT/matchmaker.yaml deploys these components to a mm101-tutorial namespace
sed "s|REGISTRY_PLACEHOLDER|$REGISTRY|g" matchmaker.yaml | sed "s|NAMESPACE_MATCHMAKER|$NAMESPACE_MATCHMAKER|g" | kubectl apply -f -
