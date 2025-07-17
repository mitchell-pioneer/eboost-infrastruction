#!/bin/bash

# WSL-compatible Ansible runner script
# This script works around WSL permission issues

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Copy project to temp directory with proper permissions
TEMP_DIR="/tmp/eboost-deploy-$(date +%s)"
print_status "Creating temporary deployment directory: $TEMP_DIR"

cp -r /mnt/c/Users/MitchellBalsam/PycharmProjects/PythonProject/eboost-infrastructure/ansible $TEMP_DIR
cd $TEMP_DIR

# Set proper permissions
chmod 755 $TEMP_DIR
chmod 644 ansible.cfg

# Run ansible with proper environment
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_PIPELINING=False
export ANSIBLE_ROLES_PATH=./roles

print_status "Testing connectivity..."
ansible all -i inventory/hosts.ini -m ping

print_status "Running deployment playbook..."
ansible-playbook -i inventory/hosts.ini playbooks/main.yml

print_status "Deployment completed!"
print_warning "Cleaning up temporary directory..."
rm -rf $TEMP_DIR

print_status "Done!"