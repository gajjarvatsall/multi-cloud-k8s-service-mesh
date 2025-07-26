# Multi-Cloud Kubernetes Platform Setup Guide

This guide provides step-by-step instructions to set up your multi-cloud Kubernetes platform with Istio service mesh, monitoring, and security features.

## Prerequisites

### Install Required Tools

```bash
# Install Helm (if not already installed)
brew install helm

# Install Google Cloud CLI (if not already installed)
brew install google-cloud-sdk

# Install Azure CLI (if not already installed)
brew install azure-cli

# Download and install Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Verify Istio installation
istioctl version
```

## Phase 1: Cloud Provider Authentication

### 1.1 AWS Authentication

```bash
# AWS CLI should already be configured
# Verify AWS connection
aws sts get-caller-identity
```

### 1.2 GCP Authentication

```bash
# Login to GCP
gcloud auth login

# Set your project (replace with your project ID)
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

### 1.3 Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription "your-subscription-id"

# Create a resource group
az group create --name multi-cloud-rg --location eastus

# Verify resource group
az group list --output table
```

## Phase 2: Infrastructure Deployment

### 2.1 Deploy AWS EKS Cluster

```bash
# Navigate to the AWS terraform directory
cd terraform/aws

# Initialize Terraform
terraform init

# Plan the deployment (review what will be created)
terraform plan

# Apply the configuration (this will take about 10-15 minutes)
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name multi-cloud-eks

# Verify the connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2.2 Deploy Azure AKS Cluster

```bash
# Navigate to Azure terraform directory
cd ../azure

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration (this will take about 10-15 minutes)
terraform apply

# Get AKS credentials
az aks get-credentials --resource-group multi-cloud-rg --name multi-cloud-aks

# Verify connection to AKS
kubectl get nodes
```

### 2.3 Deploy GCP GKE Cluster (Optional)

```bash
# Navigate to GCP terraform directory
cd ../gcp

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Get GKE credentials
gcloud container clusters get-credentials multi-cloud-gke --zone us-central1-a
```

### 2.4 Configure kubectl Contexts

```bash
# View current contexts
kubectl config get-contexts

# Rename contexts for clarity
kubectl config rename-context multi-cloud-eks aws-eks
kubectl config rename-context multi-cloud-aks azure-aks
# kubectl config rename-context gke_your-project_us-central1-a_multi-cloud-gke gcp-gke

# Verify renamed contexts
kubectl config get-contexts
```

## Phase 3: Service Mesh Setup (Per Cluster)

### 3.1 Setup Istio on AWS EKS

```bash
# Switch to AWS context
kubectl config use-context aws-eks

# Install Istio with default configuration profile
istioctl install --set values.defaultRevision=default -y

# Verify Istio installation
kubectl get pods -n istio-system

# Label namespaces for Istio injection
kubectl label namespace default istio-injection=enabled
kubectl create namespace apps
kubectl label namespace apps istio-injection=enabled

# Verify labels
kubectl get namespace -L istio-injection
```

### 3.2 Setup Istio on Azure AKS

```bash
# Switch to Azure context
kubectl config use-context azure-aks

# Install Istio on AKS
istioctl install --set values.defaultRevision=default -y

# Enable sidecar injection
kubectl create namespace apps
kubectl label namespace apps istio-injection=enabled

# Verify Istio installation
kubectl get pods -n istio-system
```

### 3.3 Setup Istio on GCP GKE (Optional)

```bash
# Switch to GCP context
kubectl config use-context gcp-gke

# Install Istio on GKE
istioctl install --set values.defaultRevision=default -y

# Enable sidecar injection
kubectl create namespace apps
kubectl label namespace apps istio-injection=enabled

# Verify Istio installation
kubectl get pods -n istio-system
```

## Phase 4: Monitoring Setup (Per Cluster)

### 4.1 Setup Monitoring on Primary Cluster (AWS)

```bash
# Switch to AWS context
kubectl config use-context aws-eks

# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus stack (includes Grafana)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=7d

# Install Kiali for service mesh observability
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Wait for Kiali to be ready
kubectl rollout status deployment/kiali -n istio-system
```

### 4.2 Setup Monitoring on Other Clusters

```bash
# Repeat the same monitoring setup for Azure
kubectl config use-context azure-aks
# [Repeat helm install commands from 4.1]

# Repeat the same monitoring setup for GCP (if deployed)
kubectl config use-context gcp-gke
# [Repeat helm install commands from 4.1]
```

## Phase 5: Sample Application Deployment

### 5.1 Deploy Sample Apps (Do this on each cluster)

```bash
# Switch to desired cluster context (start with AWS)
kubectl config use-context aws-eks

# Deploy the sample applications
kubectl apply -f kubernetes/sample-apps/

# Verify deployments
kubectl get pods -n apps
kubectl get services -n apps

# Check if Istio sidecars are injected
kubectl describe pod -n apps -l app=productpage

# Apply the gateway configuration
kubectl apply -f kubernetes/sample-apps/gateway.yaml
```

### 5.2 Setup External Access

```bash
# Get the external IP of the Istio ingress gateway
kubectl get service istio-ingressgateway -n istio-system

# Set environment variables for the gateway
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "Gateway URL: http://$GATEWAY_URL/productpage"

# Test the application
curl -s "http://$GATEWAY_URL/productpage" | grep -o "<title>.*</title>"
```

## Phase 6: Security Configuration

### 6.1 Setup mTLS

```bash
# Create a PeerAuthentication policy to enforce mTLS across the mesh
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF

# Verify mTLS is working
kubectl get peerauthentication -A

# Check TLS status
istioctl authn tls-check productpage-v1.apps.cluster.local
```

### 6.2 Setup Certificate Management

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=60s
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=60s
kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=60s

# Verify installation
kubectl get pods -n cert-manager

# Apply the cluster issuers (make sure to update the email address first!)
kubectl apply -f kubernetes/security/cluster-issuer.yaml

# Verify issuers are ready
kubectl get clusterissuer
```

### 6.3 Apply Security Policies

```bash
# Apply authorization policies
kubectl apply -f kubernetes/security/authorization-policies.yaml

# Verify policies are applied
kubectl get authorizationpolicy -n apps

# Apply rate limiting
kubectl apply -f kubernetes/security/rate-limiting.yaml

# Apply network policies
kubectl apply -f kubernetes/security/network-policies.yaml

# Verify network policies
kubectl get networkpolicy -n apps
```

## Phase 7: Verification and Testing

### 7.1 Verify Installation

```bash
# Check if Istio is running
kubectl get pods -n istio-system

# Check if apps have sidecars injected
kubectl get pods -n apps

# Check mTLS status
istioctl authn tls-check productpage-v1.apps.cluster.local

# Check authorization policies
kubectl get authorizationpolicy -n apps

# Check certificates
kubectl get certificates -A
```

### 7.2 Test Application and Security

```bash
# Test that the application still works with security policies
curl -s "http://$GATEWAY_URL/productpage" | grep -o "<title>.*</title>"

# Try to access details service directly (this should fail due to authorization policy)
kubectl exec -n apps deployment/productpage-v1 -c productpage -- curl -s details:9080/details/0

# Test from productpage (this should work)
kubectl exec -n apps deployment/productpage-v1 -c productpage -- curl -s details:9080/details/0

# Check if rate limiting is working (should get rate limited after 10 requests in 60s)
for i in $(seq 1 15); do
  echo "Request $i: $(curl -s -w "%{http_code}" -o /dev/null "http://$GATEWAY_URL/productpage")"
  sleep 1
done
```

### 7.3 Access Dashboards

```bash
# Access Kiali dashboard (in a new terminal)
istioctl dashboard kiali

# Access Grafana dashboard
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access Prometheus dashboard
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## Phase 8: Multi-Cluster Operations

### 8.1 Switch Between Clusters

```bash
# List all contexts
kubectl config get-contexts

# Switch to AWS cluster
kubectl config use-context aws-eks

# Switch to Azure cluster
kubectl config use-context azure-aks

# Switch to GCP cluster (if deployed)
kubectl config use-context gcp-gke
```

### 8.2 Deploy Apps to Multiple Clusters

```bash
# Deploy to all clusters
for context in aws-eks azure-aks; do
  echo "Deploying to $context"
  kubectl config use-context $context
  kubectl apply -f kubernetes/sample-apps/
  kubectl apply -f kubernetes/security/
done
```

## Troubleshooting

### Common Issues

1. **LoadBalancer pending**: Check cloud provider quotas and permissions
2. **Pods not starting**: Check resource limits and node capacity
3. **Istio sidecar not injected**: Verify namespace labels
4. **mTLS errors**: Check PeerAuthentication policies
5. **Rate limiting not working**: Verify Envoy filter configuration

### Useful Commands

```bash
# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check all pods across namespaces
kubectl get pods --all-namespaces

# Check Istio configuration
istioctl proxy-config cluster <pod-name> -n <namespace>

# Check service mesh status
istioctl proxy-status
```

## Notes

- Replace placeholder values (project IDs, subscription IDs, email addresses) with your actual values
- Each phase builds upon the previous one, so follow the order
- Monitor resource usage during deployment
- Set up appropriate RBAC policies for production environments
- Consider implementing backup and disaster recovery procedures
