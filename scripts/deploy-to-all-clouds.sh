#!/bin/bash

# Multi-Cloud Kubernetes Platform Deployment Script
# This script deploys the application to all configured cloud clusters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if context exists
check_context() {
    local context=$1
    if kubectl config get-contexts | grep -q "$context"; then
        return 0
    else
        return 1
    fi
}

# Function to deploy to a specific cluster
deploy_to_cluster() {
    local context=$1
    local cloud=$2
    
    print_status "Deploying to $cloud cluster ($context)..."
    
    # Switch context
    kubectl config use-context "$context"
    
    # Verify connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to $cloud cluster ($context)"
        return 1
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace apps istio-injection=enabled --overwrite
    
    # Deploy base applications
    print_status "Deploying base applications to $cloud..."
    kubectl apply -f kubernetes/sample-apps/
    
    # Deploy cloud-specific configurations
    case $cloud in
        "aws")
            print_status "Deploying AWS-specific configurations..."
            # AWS gets all services by default from sample-apps
            ;;
        "azure")
            print_status "Deploying Azure-specific configurations..."
            kubectl apply -f kubernetes/multi-cloud/productpage-azure.yaml
            kubectl apply -f kubernetes/multi-cloud/cross-cloud-gateway.yaml
            ;;
        "gcp")
            print_status "Deploying GCP-specific configurations..."
            kubectl apply -f kubernetes/multi-cloud/ratings-gcp.yaml
            ;;
    esac
    
    # Deploy security policies
    print_status "Deploying security policies to $cloud..."
    kubectl apply -f kubernetes/security/
    
    # Wait for deployments to be ready
    print_status "Waiting for deployments to be ready in $cloud..."
    kubectl wait --for=condition=available --timeout=300s deployment --all -n apps
    
    print_status "✅ Successfully deployed to $cloud cluster"
}

# Function to setup multi-cluster mesh
setup_multi_cluster_mesh() {
    print_status "Setting up multi-cluster service mesh..."
    
    # Deploy east-west gateways to each cluster
    for context in aws-eks azure-aks gcp-gke; do
        if check_context "$context"; then
            print_status "Setting up east-west gateway on $context..."
            kubectl config use-context "$context"
            kubectl apply -f kubernetes/multi-cloud/east-west-gateway.yaml
            
            # Wait for gateway to be ready
            kubectl wait --for=condition=available --timeout=300s deployment/istio-eastwestgateway -n istio-system || true
        fi
    done
    
    # Apply cluster configurations
    print_status "Applying cluster configurations..."
    for context in aws-eks azure-aks gcp-gke; do
        if check_context "$context"; then
            kubectl config use-context "$context"
            kubectl apply -f kubernetes/multi-cloud/cluster-config.yaml
        fi
    done
}

# Main deployment function
main() {
    print_status "🚀 Starting multi-cloud deployment..."
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v istioctl &> /dev/null; then
        print_error "istioctl is not installed"
        exit 1
    fi
    
    # Define clusters
    declare -A clusters
    clusters["aws-eks"]="aws"
    clusters["azure-aks"]="azure"
    clusters["gcp-gke"]="gcp"
    
    # Deploy to each available cluster
    for context in "${!clusters[@]}"; do
        if check_context "$context"; then
            deploy_to_cluster "$context" "${clusters[$context]}"
        else
            print_warning "Context $context not found, skipping ${clusters[$context]} deployment"
        fi
    done
    
    # Setup multi-cluster mesh
    setup_multi_cluster_mesh
    
    print_status "🎉 Multi-cloud deployment completed!"
    print_status "Use the following commands to check status:"
    echo "  kubectl config get-contexts"
    echo "  kubectl get pods -n apps --context=aws-eks"
    echo "  kubectl get pods -n apps --context=azure-aks"
    echo "  kubectl get pods -n apps --context=gcp-gke"
}

# Run main function
main "$@"
