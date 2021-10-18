# Load Configs
. ./config

# Delete namespace (if it exists) so that demo can be started from scrath.
kubectl delete namespace ${NAMESPACE_MATCHMAKER}

###########################################
#   Deploy Frontend
###########################################

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
