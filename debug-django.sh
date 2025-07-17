#!/bin/bash

# Django troubleshooting script
# Run this on the server to diagnose Django/Nginx issues

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

print_header "Django/Nginx Troubleshooting Script"

# Check if Django directory exists
print_header "1. Checking Django installation"
if [ -d "/var/www/django" ]; then
    print_status "Django directory exists"
    ls -la /var/www/django/
else
    print_error "Django directory does not exist"
fi

# Check Django virtual environment
print_header "2. Checking Django virtual environment"
if [ -f "/var/www/django/venv/bin/activate" ]; then
    print_status "Virtual environment exists"
    /var/www/django/venv/bin/python --version
else
    print_error "Virtual environment does not exist"
fi

# Check if Django project exists
print_header "3. Checking Django project"
if [ -f "/var/www/django/manage.py" ]; then
    print_status "Django project exists"
    ls -la /var/www/django/
else
    print_error "Django manage.py not found"
fi

# Check Nginx status
print_header "4. Checking Nginx status"
systemctl is-active --quiet nginx
if [ $? -eq 0 ]; then
    print_status "Nginx is running"
else
    print_error "Nginx is not running"
    sudo systemctl status nginx
fi

# Check Nginx configuration
print_header "5. Checking Nginx configuration"
if [ -f "/etc/nginx/sites-available/django" ]; then
    print_status "Nginx Django config exists"
    cat /etc/nginx/sites-available/django
else
    print_error "Nginx Django config does not exist"
fi

if [ -L "/etc/nginx/sites-enabled/django" ]; then
    print_status "Nginx Django site is enabled"
else
    print_error "Nginx Django site is not enabled"
fi

# Test Nginx configuration
print_header "6. Testing Nginx configuration"
sudo nginx -t

# Check Supervisor status
print_header "7. Checking Supervisor status"
systemctl is-active --quiet supervisor
if [ $? -eq 0 ]; then
    print_status "Supervisor is running"
    sudo supervisorctl status
else
    print_error "Supervisor is not running"
    sudo systemctl status supervisor
fi

# Check Supervisor Django configuration
print_header "8. Checking Supervisor Django configuration"
if [ -f "/etc/supervisor/conf.d/django.conf" ]; then
    print_status "Supervisor Django config exists"
    cat /etc/supervisor/conf.d/django.conf
else
    print_error "Supervisor Django config does not exist"
fi

# Check what's listening on ports
print_header "9. Checking port listeners"
print_status "Port 80 listeners:"
sudo netstat -tlnp | grep :80 || echo "Nothing listening on port 80"

print_status "Port 443 listeners:"
sudo netstat -tlnp | grep :443 || echo "Nothing listening on port 443"

print_status "Port 8000 listeners:"
sudo netstat -tlnp | grep :8000 || echo "Nothing listening on port 8000"

# Check Django logs
print_header "10. Checking Django logs"
if [ -f "/var/log/supervisor/django.log" ]; then
    print_status "Django logs (last 20 lines):"
    tail -20 /var/log/supervisor/django.log
else
    print_error "Django log file does not exist"
fi

if [ -f "/var/log/supervisor/django_error.log" ]; then
    print_status "Django error logs (last 20 lines):"
    tail -20 /var/log/supervisor/django_error.log
else
    print_warning "Django error log file does not exist"
fi

# Check Nginx logs
print_header "11. Checking Nginx logs"
if [ -f "/var/log/nginx/django_access.log" ]; then
    print_status "Nginx access logs (last 10 lines):"
    tail -10 /var/log/nginx/django_access.log
else
    print_warning "Nginx access log does not exist"
fi

if [ -f "/var/log/nginx/django_error.log" ]; then
    print_status "Nginx error logs (last 10 lines):"
    tail -10 /var/log/nginx/django_error.log
else
    print_warning "Nginx error log does not exist"
fi

# Test Django directly
print_header "12. Testing Django directly"
if [ -f "/var/www/django/manage.py" ]; then
    print_status "Testing Django installation:"
    cd /var/www/django
    sudo -u django /var/www/django/venv/bin/python manage.py check
else
    print_error "Cannot test Django - manage.py not found"
fi

# Check firewall
print_header "13. Checking firewall"
sudo ufw status

print_header "Troubleshooting complete!"
print_status "If you found issues, try these commands:"
echo "- Restart Nginx: sudo systemctl restart nginx"
echo "- Restart Supervisor: sudo systemctl restart supervisor"
echo "- Reload Supervisor: sudo supervisorctl reload"
echo "- Check Django manually: cd /var/www/django && sudo -u django /var/www/django/venv/bin/python manage.py runserver 0.0.0.0:8000"