#!/bin/bash

# PostgreSQL setup test script
# This script tests the PostgreSQL setup outside of Ansible

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

# Test variables
DB_NAME="test_eboost_db"
DB_USER="test_eboost_user"
DB_PASSWORD="test_password"

print_status "Testing PostgreSQL setup..."

# Test 1: Check if PostgreSQL is installed
print_status "1. Checking PostgreSQL installation..."
if command -v psql &> /dev/null; then
    print_status "✓ PostgreSQL client is installed"
else
    print_error "✗ PostgreSQL client not found"
    exit 1
fi

# Test 2: Check if PostgreSQL service is running
print_status "2. Checking PostgreSQL service..."
if systemctl is-active --quiet postgresql; then
    print_status "✓ PostgreSQL service is running"
else
    print_warning "PostgreSQL service is not running"
fi

# Test 3: Check if we can connect as postgres user
print_status "3. Testing postgres user connection..."
if sudo -u postgres psql -c "SELECT version();" &> /dev/null; then
    print_status "✓ Can connect as postgres user"
else
    print_error "✗ Cannot connect as postgres user"
    exit 1
fi

# Test 4: Test user creation
print_status "4. Testing user creation..."
if sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1; then
    print_status "User $DB_USER already exists, dropping..."
    sudo -u postgres psql -c "DROP USER $DB_USER;"
fi

if sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"; then
    print_status "✓ User creation successful"
else
    print_error "✗ User creation failed"
    exit 1
fi

# Test 5: Test database creation
print_status "5. Testing database creation..."
if sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    print_status "Database $DB_NAME already exists, dropping..."
    sudo -u postgres psql -c "DROP DATABASE $DB_NAME;"
fi

if sudo -u postgres createdb -O $DB_USER $DB_NAME; then
    print_status "✓ Database creation successful"
else
    print_error "✗ Database creation failed"
    exit 1
fi

# Test 6: Test privileges
print_status "6. Testing privilege grants..."
if sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"; then
    print_status "✓ Privilege grant successful"
else
    print_error "✗ Privilege grant failed"
    exit 1
fi

# Test 7: Test connection with new user
print_status "7. Testing connection with new user..."
if PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" &> /dev/null; then
    print_status "✓ User can connect to database"
else
    print_error "✗ User cannot connect to database"
    exit 1
fi

# Cleanup
print_status "8. Cleaning up test resources..."
sudo -u postgres psql -c "DROP DATABASE $DB_NAME;"
sudo -u postgres psql -c "DROP USER $DB_USER;"
print_status "✓ Cleanup completed"

print_status "All PostgreSQL tests passed! ✓"