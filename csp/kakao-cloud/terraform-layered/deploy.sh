#!/usr/bin/env bash
set -e

# K-PaaS Layered Terraform Deployment Script
# Usage: ./deploy.sh [all|network|lb|cluster|destroy]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check terraform.tfvars exists in all layers
check_tfvars() {
    local missing=0
    for layer in 01-network 02-loadbalancer 03-cluster; do
        if [ ! -f "$layer/terraform.tfvars" ]; then
            log_error "$layer/terraform.tfvars not found"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        log_error "Please create terraform.tfvars files. See terraform.tfvars.example"
        exit 1
    fi
}

deploy_layer() {
    local layer=$1
    local name=$2

    log_info "=========================================="
    log_info "Deploying Layer: $name"
    log_info "=========================================="

    cd "$SCRIPT_DIR/$layer"

    if [ ! -d ".terraform" ]; then
        log_info "Initializing terraform..."
        terraform init
    fi

    log_info "Applying terraform..."
    terraform apply -auto-approve

    log_info "$name deployment completed!"
    cd "$SCRIPT_DIR"
}

destroy_layer() {
    local layer=$1
    local name=$2

    log_warn "Destroying Layer: $name"

    cd "$SCRIPT_DIR/$layer"

    if [ -d ".terraform" ]; then
        terraform destroy -auto-approve || true
    fi

    cd "$SCRIPT_DIR"
}

deploy_all() {
    check_tfvars

    log_info "Starting Full K-PaaS Deployment"
    log_info "This will deploy: Network → LoadBalancer → Cluster"
    echo ""

    deploy_layer "01-network" "Network (VPC, Subnet)"
    deploy_layer "02-loadbalancer" "LoadBalancer (Master LB, Worker LB, Security Group)"
    deploy_layer "03-cluster" "Cluster (Compute, K-PaaS Installation)"

    echo ""
    log_info "=========================================="
    log_info "K-PaaS Deployment Completed!"
    log_info "=========================================="
    echo ""

    # Show outputs
    cd "$SCRIPT_DIR/03-cluster"
    echo "SSH Command:"
    terraform output -raw ssh_command 2>/dev/null || true
    echo ""
    echo ""
    echo "Installation Log Command:"
    terraform output -raw install_log_command 2>/dev/null || true
    echo ""
}

destroy_all() {
    log_warn "=========================================="
    log_warn "Destroying ALL K-PaaS Infrastructure"
    log_warn "=========================================="
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Cancelled."
        exit 0
    fi

    # Destroy in reverse order
    destroy_layer "03-cluster" "Cluster"
    destroy_layer "02-loadbalancer" "LoadBalancer"
    destroy_layer "01-network" "Network"

    log_info "All infrastructure destroyed."
}

destroy_cluster_only() {
    log_warn "Destroying Cluster Layer Only (Network/LB preserved)"

    cd "$SCRIPT_DIR/03-cluster"
    if [ -d ".terraform" ]; then
        terraform destroy -auto-approve
    fi

    log_info "Cluster destroyed. Network and LoadBalancer preserved."
}

show_status() {
    echo "=== Layer Status ==="
    for layer in 01-network 02-loadbalancer 03-cluster; do
        if [ -f "$layer/terraform.tfstate" ]; then
            resources=$(grep -c '"type":' "$layer/terraform.tfstate" 2>/dev/null || echo "0")
            echo "$layer: $resources resources"
        else
            echo "$layer: not deployed"
        fi
    done
}

show_help() {
    echo "K-PaaS Layered Terraform Deployment"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  all              Deploy all layers (Network → LB → Cluster)"
    echo "  network          Deploy Network layer only"
    echo "  lb               Deploy LoadBalancer layer only"
    echo "  cluster          Deploy Cluster layer only"
    echo "  destroy          Destroy all layers"
    echo "  destroy-cluster  Destroy cluster only (preserve Network/LB)"
    echo "  status           Show deployment status"
    echo "  help             Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 all              # Full deployment"
    echo "  $0 destroy-cluster  # Redeploy cluster faster"
    echo "  $0 cluster          # Deploy cluster again"
}

# Main
case "${1:-all}" in
    all)
        deploy_all
        ;;
    network)
        check_tfvars
        deploy_layer "01-network" "Network"
        ;;
    lb|loadbalancer)
        check_tfvars
        deploy_layer "02-loadbalancer" "LoadBalancer"
        ;;
    cluster)
        check_tfvars
        deploy_layer "03-cluster" "Cluster"
        ;;
    destroy)
        destroy_all
        ;;
    destroy-cluster)
        destroy_cluster_only
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
