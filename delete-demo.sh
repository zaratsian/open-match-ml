# Load Config
. ./config

echo "Deleting Demo Namespace (${NAMESPACE_MATCHMAKER}) in 5 seconds..."
sleep 5
kubectl delete namespace ${NAMESPACE_MATCHMAKER}
echo ""
echo ""
echo "Deleting Open Match kubernetes cluster (${GKE_CLUSTER_NAME})..."
gcloud container clusters list
gcloud container clusters delete ${GKE_CLUSTER_NAME} --zone ${GKE_MACHINE_ZONE}
gcloud container clusters list