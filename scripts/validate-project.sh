#!/bin/bash

# Multi-Cloud Kubernetes Platform Validation Script
# This script validates all configurations without actually deploying

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to validate YAML files
validate_yaml() {
    local file=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ ! -f "$file" ]]; then
        print_error "$description: File not found ($file)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    # Check if it's valid YAML
    if kubectl apply --dry-run=client -f "$file" >/dev/null 2>&1; then
        print_status "$description: Valid YAML syntax"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "$description: Invalid YAML syntax ($file)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to validate Terraform files
validate_terraform() {
    local dir=$1
    local cloud=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ ! -d "$dir" ]]; then
        print_error "$cloud Terraform: Directory not found ($dir)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
    
    cd "$dir"
    
    # Check if terraform files exist
    if [[ ! -f "main.tf" ]]; then
        print_error "$cloud Terraform: main.tf not found"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        cd - >/dev/null
        return 1
    fi
    
    # Validate terraform syntax
    if terraform validate >/dev/null 2>&1; then
        print_status "$cloud Terraform: Valid syntax"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        cd - >/dev/null
        return 0
    else
        print_error "$cloud Terraform: Invalid syntax"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        cd - >/dev/null
        return 1
    fi
}

# Function to check file existence
check_file_exists() {
    local file=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ -f "$file" ]]; then
        print_status "$description: File exists"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "$description: File missing ($file)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to validate project structure
validate_structure() {
    print_info "🔍 Validating project structure..."
    
    # Check main directories
    local dirs=("terraform" "kubernetes" "monitoring" "scripts" "docs")
    
    for dir in "${dirs[@]}"; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if [[ -d "$dir" ]]; then
            print_status "Directory exists: $dir"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            print_error "Directory missing: $dir"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
    done
    
    # Check essential files
    check_file_exists "README.md" "README file"
    check_file_exists "SETUP_GUIDE.md" "Setup guide"
    check_file_exists ".gitignore" "Git ignore file"
    check_file_exists "QUICK_REFERENCE.md" "Quick reference"
}

# Main validation function
main() {
    echo "🚀 Multi-Cloud Kubernetes Platform Validation"
    echo "============================================="
    
    # Validate project structure
    validate_structure
    
    # Validate Terraform configurations
    print_info "🏗️  Validating Terraform configurations..."
    validate_terraform "terraform/aws" "AWS"
    validate_terraform "terraform/azure" "Azure" 
    validate_terraform "terraform/gcp" "GCP"
    
    # Validate Kubernetes manifests
    print_info "☸️  Validating Kubernetes manifests..."
    
    # Sample applications
    validate_yaml "kubernetes/sample-apps/productpage.yaml" "Productpage service"
    validate_yaml "kubernetes/sample-apps/details.yaml" "Details service"
    validate_yaml "kubernetes/sample-apps/reviews.yaml" "Reviews service"
    validate_yaml "kubernetes/sample-apps/gateway.yaml" "Application gateway"
    
    # Multi-cloud configurations
    validate_yaml "kubernetes/multi-cloud/cluster-config.yaml" "Multi-cluster config"
    validate_yaml "kubernetes/multi-cloud/east-west-gateway.yaml" "East-west gateway"
    validate_yaml "kubernetes/multi-cloud/cross-cloud-gateway.yaml" "Cross-cloud gateway"
    validate_yaml "kubernetes/multi-cloud/productpage-azure.yaml" "Azure productpage"
    validate_yaml "kubernetes/multi-cloud/ratings-gcp.yaml" "GCP ratings"
    validate_yaml "kubernetes/multi-cloud/cluster-sercets.yaml" "Cluster secrets"
    
    # Security configurations
    validate_yaml "kubernetes/security/authorization-policies.yaml" "Authorization policies"
    validate_yaml "kubernetes/security/network-policies.yaml" "Network policies"
    validate_yaml "kubernetes/security/rate-limiting.yaml" "Rate limiting"
    validate_yaml "kubernetes/security/cluster-issuer.yaml" "Cluster issuer"
    
    # Monitoring configurations
    validate_yaml "monitoring/prometheus/prometheus-config.yaml" "Prometheus config"
    
    # Check scripts
    print_info "📜 Validating scripts..."
    check_file_exists "scripts/deploy-to-all-clouds.sh" "Multi-cloud deployment script"
    
    # Summary
    echo ""
    echo "📊 VALIDATION SUMMARY"
    echo "===================="
    echo -e "Total checks: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo ""
        print_status "🎉 All validations passed! Your project is ready for deployment."
        echo ""
        echo "📋 NEXT STEPS:"
        echo "1. Update placeholder values in cluster-secrets.yaml"
        echo "2. Update email in cluster-issuer.yaml"
        echo "3. Review and customize terraform.tfvars files"
        echo "4. Run terraform plan for each cloud provider"
        echo "5. Deploy infrastructure using terraform apply"
        echo "6. Follow the SETUP_GUIDE.md for complete deployment"
        
        return 0
    else
        echo ""
        print_error "❌ Some validations failed. Please fix the issues before deployment."
        return 1
    fi
}

# Check prerequisites
print_info "🔧 Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl not found - YAML validation will be limited"
fi

if ! command -v terraform &> /dev/null; then
    print_warning "terraform not found - Terraform validation will be skipped"
fi

# Run main validation
main "$@"
