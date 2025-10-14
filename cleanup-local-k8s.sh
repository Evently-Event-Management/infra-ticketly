#!/bin/bash

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}=== Ticketly Local Kubernetes Cleanup ===${NC}"
echo -e "${YELLOW}This will remove all Ticketly resources from your local Kubernetes cluster.${NC}"
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${GREEN}Cleanup cancelled.${NC}"
    exit 0
fi

# Check if minikube or kind is installed and running
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    KUBE_TOOL="minikube"
    echo -e "${GREEN}Found running Minikube.${NC}"
elif command -v kind &> /dev/null && kind get clusters | grep -q "ticketly"; then
    KUBE_TOOL="kind"
    echo -e "${GREEN}Found kind cluster 'ticketly'.${NC}"
else
    echo -e "${YELLOW}No running Kubernetes cluster found. Nothing to clean up.${NC}"
    exit 0
fi

# Delete the namespace (this will delete all resources in it)
echo -e "${GREEN}Deleting ticketly namespace...${NC}"
kubectl delete namespace ticketly --wait=false

# Wait for namespace deletion (but don't wait forever)
echo -e "${GREEN}Waiting for namespace deletion to complete...${NC}"
timeout 60 bash -c 'until ! kubectl get namespace ticketly &> /dev/null; do sleep 2; done' || true

# If using kind, offer to delete the cluster
if [ "$KUBE_TOOL" = "kind" ]; then
    read -p "Do you want to delete the kind cluster 'ticketly'? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo -e "${GREEN}Deleting kind cluster 'ticketly'...${NC}"
        kind delete cluster --name ticketly
        echo -e "${GREEN}Kind cluster 'ticketly' deleted.${NC}"
    fi
fi

# If using minikube, offer to stop it
if [ "$KUBE_TOOL" = "minikube" ]; then
    read -p "Do you want to stop minikube? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo -e "${GREEN}Stopping minikube...${NC}"
        minikube stop
        echo -e "${GREEN}Minikube stopped.${NC}"
    fi
fi

echo -e "${GREEN}Cleanup completed!${NC}"