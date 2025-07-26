# Multi-Cloud Kubernetes Platform with Service Mesh

## Project Overview

A comprehensive multi-cloud Kubernetes platform with Istio service mesh, unified monitoring, and disaster recovery capabilities.

## Architecture

- AWS EKS
- Azure AKS
- Google GKE
- Istio Service Mesh
- Prometheus & Grafana Monitoring
- Terraform Infrastructure as Code

## Getting Started

### Quick Start

For a complete, step-by-step setup guide, see [SETUP_GUIDE.md](./SETUP_GUIDE.md)

### Setup Order

1. **Prerequisites**: Install required tools (Helm, cloud CLIs, Istio)
2. **Authentication**: Configure access to all cloud providers
3. **Infrastructure**: Deploy Kubernetes clusters using Terraform
4. **Service Mesh**: Install and configure Istio on each cluster
5. **Monitoring**: Set up Prometheus, Grafana, and Kiali
6. **Applications**: Deploy sample microservices
7. **Security**: Configure mTLS, authorization, and network policies
8. **Verification**: Test all components and security features

### Command Files (Legacy - Use SETUP_GUIDE.md instead)

- `commands/commands_to_start.txt` - General setup commands
- `commands/aws_setup.txt` - AWS-specific setup
- `commands/azure_setup.txt` - Azure-specific setup
- `commands/gcp_setup.txt` - GCP-specific setup
