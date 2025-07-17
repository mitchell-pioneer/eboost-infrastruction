#!/bin/bash

# EBoost Infrastructure Destruction Script

set -e

echo "Starting EBoost Infrastructure Destruction..."

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

# Confirm destruction
confirm_destruction() {
    print_warning "This will destroy all EBoost infrastructure resources!"
    print_warning "This action cannot be undone!"
    
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_status "Destruction cancelled."
        exit 0
    fi
}

# Destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying infrastructure with Terraform..."
    
    cd terraform
    
    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No terraform state found. Nothing to destroy."
        cd ..
        return
    fi
    
    # Destroy the infrastructure
    terraform destroy -auto-approve
    
    cd ..
    
    print_status "Infrastructure destruction completed."
}

# Clean up local files
cleanup_local() {
    print_status "Cleaning up local files..."
    
    # Reset inventory file
    sed -i 's/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/YOUR_SERVER_IP/g' ansible/inventory/hosts.ini
    
    print_status "Local cleanup completed."
}

# Main destruction function
main() {
    confirm_destruction
    
    print_status "Starting EBoost destruction process..."
    
    destroy_infrastructure
    cleanup_local
    
    print_status "Destruction completed successfully!"
}

# Run main function
main "$@"