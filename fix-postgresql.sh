#!/bin/bash

# PostgreSQL cluster fix script
# Run this on the remote server to fix PostgreSQL cluster issues

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_status "Starting PostgreSQL cluster fix..."

# Step 1: Stop PostgreSQL service
print_status "1. Stopping PostgreSQL service..."
systemctl stop postgresql || true

# Step 2: Kill any remaining PostgreSQL processes
print_status "2. Killing any remaining PostgreSQL processes..."
pkill -f postgres || true
sleep 3

# Step 3: Check existing clusters
print_status "3. Checking existing clusters..."
echo "Current clusters:"
pg_lsclusters || true

# Step 4: Remove broken cluster
print_status "4. Removing any broken cluster..."
pg_dropcluster --stop 14 main || true

# Step 4.5: Remove configuration and data directories
print_status "4.5. Removing PostgreSQL directories..."
rm -rf /etc/postgresql/14/main || true
rm -rf /var/lib/postgresql/14/main || true

# Step 5: Create fresh cluster
print_status "5. Creating fresh PostgreSQL cluster..."
pg_createcluster 14 main

# Step 6: Start cluster
print_status "6. Starting PostgreSQL cluster..."
pg_ctlcluster 14 main start

# Step 7: Enable and start service
print_status "7. Enabling and starting PostgreSQL service..."
systemctl enable postgresql
systemctl start postgresql

# Step 8: Wait for PostgreSQL to be ready
print_status "8. Waiting for PostgreSQL to be ready..."
sleep 5

# Step 9: Test connection
print_status "9. Testing PostgreSQL connection..."
if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
    print_status "✓ PostgreSQL is working correctly!"
else
    print_error "✗ PostgreSQL connection test failed"
    exit 1
fi

# Step 10: Show cluster status
print_status "10. Final cluster status:"
pg_lsclusters

print_status "PostgreSQL cluster fix completed successfully!"
print_status "You can now run the Ansible deployment again."