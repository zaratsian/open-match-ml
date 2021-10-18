# Load Config
include ../config

enable-gcp-services:
	# Enable necessary GCP services
	gcloud services enable container.googleapis.com
	gcloud services enable artifactregistry.googleapis.com
	gcloud services enable containerregistry.googleapis.com

setup-artifact-repo:
	# Setup Google Artifact Registry
	gcloud artifacts repositories create ${GCP_ARTIFACT_REGISTRY_NAME} \
	--repository-format=docker \
	--location=${GCP_ARTIFACT_REGISTRY_REGION} \
	--description="Open Match Docker Repo"
    
	# Verify that repo has been created
	gcloud artifacts repositories list

setup-docker-auth:
	# Set up authentication to Docker repositories in the region
	gcloud auth configure-docker "${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev"

install-open-match:
	# Create a GKE Cluster in this project
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
	#kubectl create namespace open-match
    
	# Install the core Open Match services.
	# 01-open-match-core.yaml installs Open Match with the default configs.
	kubectl apply --namespace open-match \
		-f https://open-match.dev/install/v1.2.0/yaml/01-open-match-core.yaml
    
	# Get the Pod State
	# NOTE: Open Match needs to be customized to run as a Matchmaker.
	# This custom configuration is provided to the Open Match 
	# components via a ConfigMap (om-configmap-override). 
	# Thus, starting the core service pods will remain in 
	# ContainerCreating until this config map is available.
	kubectl get -n open-match pod
    
	# Install the Default Evaluator
	kubectl apply --namespace open-match \
		-f https://open-match.dev/install/v1.2.0/yaml/06-open-match-override-configmap.yaml \
		-f https://open-match.dev/install/v1.2.0/yaml/07-open-match-default-evaluator.yaml

build-om-frontend:
	REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
	echo "Artifact Registry Path: ${REGISTRY}"
    
	# Create Namespace
	kubectl create namespace ${NAMESPACE}

	# Build the Frontend image.
	docker build -t $REGISTRY/${NAMESPACE}-frontend -f containers/frontend/Dockerfile .

	# Push the Frontend image to the configured Registry.
	docker push $REGISTRY/${NAMESPACE}-frontend

build-om-director:
	REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
	echo "Artifact Registry Path: ${REGISTRY}"

	#kubectl create namespace ${NAMESPACE}

	# Build the image.
	docker build -t $REGISTRY/${NAMESPACE}-director -f containers/director/Dockerfile .

	# Push the image to the configured Registry.
	docker push $REGISTRY/${NAMESPACE}-director

build-om-matchfunction:
	REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
	echo "Artifact Registry Path: ${REGISTRY}"

	#kubectl create namespace ${NAMESPACE}

	# Build the image.
	docker build -t $REGISTRY/${NAMESPACE}-matchfunction -f containers/matchfunction/Dockerfile .

	# Push the image to the configured Registry.
	docker push $REGISTRY/${NAMESPACE}-matchfunction

deploy-om:
	REGISTRY="${GCP_ARTIFACT_REGISTRY_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_ARTIFACT_REGISTRY_NAME}"
	echo "Artifact Registry Path: ${REGISTRY}"

	# Deploy the Match Function, the Game Frontend and the Director 
	# to the same cluster as Open Match deployment but to a different namespace. 
	# The $TUTORIALROOT/matchmaker.yaml deploys these components to a mm101-tutorial namespace
	sed "s|REGISTRY_PLACEHOLDER|$REGISTRY|g" matchmaker.yaml | kubectl apply -f -

logs-frontend:
	kubectl logs -n mm102-tutorial pod/mm102-tutorial-frontend

logs-director:
	kubectl logs -n mm102-tutorial pod/mm102-tutorial-director

logs-matchfunction:
	kubectl logs -n mm102-tutorial pod/mm102-tutorial-matchfunction

