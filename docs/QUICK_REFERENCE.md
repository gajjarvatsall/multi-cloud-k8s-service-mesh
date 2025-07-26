# Quick Reference Commands

## Context Switching

```bash
# List all contexts
kubectl config get-contexts

# Switch contexts
kubectl config use-context aws-eks
kubectl config use-context azure-aks
kubectl config use-context gcp-gke
```

## Cluster Status Checks

```bash
# Basic cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Istio status
kubectl get pods -n istio-system
istioctl proxy-status

# Application status
kubectl get pods -n apps
kubectl get svc -n apps
```

## Access Dashboards

```bash
# Kiali (Service Mesh Dashboard)
istioctl dashboard kiali

# Grafana (Monitoring Dashboard)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus (Metrics Dashboard)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## Application URLs

```bash
# Get gateway URL
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

# Test application
curl -s "http://$GATEWAY_URL/productpage"
```

## Security Verification

```bash
# Check mTLS
istioctl authn tls-check productpage-v1.apps.cluster.local

# Check policies
kubectl get authorizationpolicy -n apps
kubectl get networkpolicy -n apps
kubectl get peerauthentication -A
```

## Multi-Cluster Operations

```bash
# Deploy to all clusters
for context in aws-eks azure-aks; do
  echo "Deploying to $context"
  kubectl config use-context $context
  kubectl apply -f kubernetes/sample-apps/
done
```

## Troubleshooting

```bash
# Check logs
kubectl logs -f deployment/productpage-v1 -n apps
kubectl logs -f deployment/details-v1 -n apps

# Check Istio configuration
istioctl proxy-config cluster productpage-v1 -n apps

# Describe resources
kubectl describe pod <pod-name> -n apps
kubectl describe svc <service-name> -n apps
```
