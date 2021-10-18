# Load Config
. ./config

kubectl logs -n ${NAMESPACE_MATCHMAKER} pod/${NAMESPACE_MATCHMAKER}-director
