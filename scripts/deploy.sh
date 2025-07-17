#!/bin/bash

# EBoost Infrastructure Deployment Script

set -e

echo "Starting EBoost Infrastructure Deployment..."

# Color codes for output
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

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI is not installed. You may need it for authentication."
    fi
    
    print_status "Dependencies check completed."
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars file not found. Please create it from terraform.tfvars.example"
        exit 1
    fi
    
    # Initialize Terraform
    terraform init
    
    # Plan the deployment
    terraform plan -out=tfplan
    
    # Apply the deployment
    terraform apply tfplan
    
    # Get the instance IP
    INSTANCE_IP=$(terraform output -raw instance_ip)
    print_status "Instance IP: $INSTANCE_IP"
    
    cd ..
    
    # Update Ansible inventory with the new IP
    sed -i "s/YOUR_SERVER_IP/$INSTANCE_IP/g" ansible/inventory/hosts.ini
    
    print_status "Infrastructure deployment completed."
}

# Configure services with Ansible
configure_services() {
    print_status "Configuring services with Ansible..."
    
    cd ansible
    
    # Wait for SSH to be available
    print_status "Waiting for SSH to be available..."
    sleep 60
    
    # Test connectivity
    ANSIBLE_ROLES_PATH=./roles ansible all -m ping
    
    # Run the main playbook
    ANSIBLE_ROLES_PATH=./roles ansible-playbook playbooks/main.yml
    
    cd ..
    
    print_status "Service configuration completed."
}

# Main deployment function
main() {
    print_status "Starting EBoost deployment process..."
    
    check_dependencies
    deploy_infrastructure
    configure_services
    
    print_status "Deployment completed successfully!"
    print_status "You can access your Django admin at: http://$(cd terraform && terraform output -raw instance_ip)/admin/"
    print_status "Default admin credentials are in ansible/inventory/group_vars/all.yml"
    print_warning "Remember to change default passwords in production!"
}

# Run main function
main "$@"